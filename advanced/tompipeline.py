"""MetaMind-style Theory-of-Mind pipeline."""

from __future__ import annotations
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any
import json

from core.db import CoreDB


@dataclass
class Conversation:
    """Conversation data structure."""
    participants: List[str]
    messages: List[Dict[str, Any]]
    context: Optional[Dict[str, Any]] = None
    

class TheoryOfMindPipeline:
    """Three-stage ToM reasoning pipeline."""
    
    def __init__(self, db_path: str = "/tmp/social.db"):
        self.db = CoreDB(db_path)
        self.logger = self._setup_logger()
        
    def _setup_logger(self):
        """Setup a simple logger."""
        import logging
        logger = logging.getLogger(__name__)
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
        return logger
    
    def process(self, conversation: Conversation) -> Dict[str, Any]:
        """Process a conversation through the ToM pipeline.
        
        Args:
            conversation: Conversation object to process
            
        Returns:
            Dictionary with analysis results
        """
        self.logger.info("Starting ToM pipeline processing")
        
        # Stage 1: Social context analysis
        social_context = self._analyze_social_context(conversation)
        
        # Stage 2: Intent and sentiment analysis
        intents = self._analyze_intents(conversation)
        
        # Stage 3: Response validation
        validated_response = self._validate_response(conversation, social_context, intents)
        
        result = {
            "summary": f"Analyzed conversation between {', '.join(conversation.participants)}",
            "social_context": social_context,
            "intents": intents,
            "validated_response": validated_response,
            "confidence": self._calculate_confidence(social_context, intents)
        }
        
        self.logger.info(f"ToM processing completed: {result['summary']}")
        return result
    
    def _analyze_social_context(self, conversation: Conversation) -> Dict[str, Any]:
        """Analyze social relationships and history."""
        context = {}
        
        # Get or create person records
        for person in conversation.participants:
            person_data = self.db.get_person(person)
            if person_data:
                context[person] = {
                    "roles": person_data.get("roles", []),
                    "trust_score": float(person_data["trust_score"]),
                    "last_active": person_data.get("last_active")
                }
            else:
                context[person] = {
                    "roles": [],
                    "trust_score": 0.5,
                    "last_active": None
                }
        
        # Get recent interactions
        for person in conversation.participants:
            events = self.db.get_recent_events_for_person(person, limit=3)
            if events:
                context[person]["recent_interactions"] = events
        
        return context
    
    def _analyze_intents(self, conversation: Conversation) -> List[Dict[str, Any]]:
        """Analyze intents and sentiments."""
        intents = []
        
        for msg in conversation.messages:
            intent = {
                "sender": msg["sender"],
                "text": msg["text"][:100] + "..." if len(msg["text"]) > 100 else msg["text"],
                "intent": self._classify_intent(msg["text"]),
                "sentiment": self._analyze_sentiment(msg["text"]),
                "keywords": self._extract_keywords(msg["text"])
            }
            intents.append(intent)
        
        return intents
    
    def _validate_response(self, conversation: Conversation, social_context: Dict[str, Any], intents: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Validate response based on social context."""
        # Simplified validation
        if not conversation.messages:
            return {"valid": False, "reason": "No messages to validate"}
        
        last_msg = conversation.messages[-1]
        response = {
            "valid": True,
            "appropriate": self._check_appropriateness(last_msg, social_context),
            "trust_aware": self._adjust_for_trust(last_msg, social_context),
            "summary": f"Response to {last_msg['sender']}'s message"
        }
        return response
    
    def _calculate_confidence(self, social_context: Dict[str, Any], intents: List[Dict[str, Any]]) -> float:
        """Calculate overall confidence score."""
        # Simple heuristic
        base_confidence = 0.7
        
        # Adjust based on trust scores
        if intents:
            sender = intents[-1]["sender"]
            trust = social_context.get(sender, {}).get("trust_score", 0.5)
            base_confidence = 0.5 * base_confidence + 0.5 * trust
        
        return min(1.0, max(0.0, base_confidence))
    
    def _classify_intent(self, text: str) -> str:
        """Simple intent classification."""
        text_lower = text.lower()
        if any(word in text_lower for word in ["promise", "commit", "will"]):
            return "commitment"
        elif any(word in text_lower for word in ["thanks", "appreciate"]):
            return "gratitude"
        elif any(word in text_lower for word in ["help", "assist", "support"]):
            return "request"
        else:
            return "statement"
    
    def _analyze_sentiment(self, text: str) -> str:
        """Simple sentiment analysis."""
        text_lower = text.lower()
        positive_words = ["good", "great", "excellent", "happy", "thank"]
        negative_words = ["bad", "sad", "angry", "upset", "fail"]
        
        if any(word in text_lower for word in positive_words):
            return "positive"
        elif any(word in text_lower for word in negative_words):
            return "negative"
        else:
            return "neutral"
    
    def _extract_keywords(self, text: str) -> List[str]:
        """Extract keywords from text."""
        words = text.split()
        # Filter out common words
        common = {"the", "and", "or", "but", "a", "an", "to", "of", "in", "for"}
        keywords = [word.strip(".,!?:;") for word in words if word.lower() not in common and len(word) > 2]
        return list(set(keywords))[:5]
    
    def _check_appropriateness(self, message: Dict[str, Any], social_context: Dict[str, Any]) -> bool:
        """Check if a response would be appropriate."""
        sender = message["sender"]
        sender_trust = social_context.get(sender, {}).get("trust_score", 0.5)
        # If sender has low trust, be more cautious
        return sender_trust > 0.3
    
    def _adjust_for_trust(self, message: Dict[str, Any], social_context: Dict[str, Any]) -> Dict[str, Any]:
        """Adjust response based on trust levels."""
        adjustments = {}
        sender = message["sender"]
        trust = social_context.get(sender, {}).get("trust_score", 0.5)
        
        if trust < 0.4:
            adjustments["tone"] = "formal"
            adjustments["verification"] = "required"
        elif trust < 0.7:
            adjustments["tone"] = "neutral"
            adjustments["verification"] = "recommended"
        else:
            adjustments["tone"] = "casual"
            adjustments["verification"] = "light"
        
        return adjustments
