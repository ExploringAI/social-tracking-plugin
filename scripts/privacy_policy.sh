#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Privacy Policy Generator
This script generates a privacy policy.
"""

import sys
from pathlib import Path
from datetime import datetime

def generate_privacy_policy():
    """Generate a privacy policy."""
    policy = f"""# Social Tracking Plugin Privacy Policy

Effective Date: {datetime.now().strftime("%B %d, %Y")}
Plugin Version: 0.3.0

## Introduction

This Privacy Policy describes how the Social Tracking Plugin for Hermes AI ("we," "us," or "our") collects, uses, and discloses your information when you use our plugin (the "Plugin").

By using the Plugin, you agree to the collection and use of information in accordance with this Privacy Policy. If you do not agree with this Privacy Policy, please do not use the Plugin.

## What Information We Collect

### Personal Information
We collect the following personal information:
- **Names**: When persons are mentioned in conversations
- **Roles**: User-defined roles for persons
- **Interactions**: Summaries of conversations and interactions
- **Trust Scores**: Automated trust metrics
- **Relationship Information**: Types and strengths of relationships
- **Commitment Data**: Promises, deadlines, and statuses

### Automatically Collected Information
- **Timestamps**: When interactions occur
- **Event Types**: Categories of interactions
- **Technical Data**: None (plugin runs locally)

## How We Collect Information

### Direct Collection
- **User Commands**: When you use social tracking commands
- **Entity Extraction**: Automated extraction from conversations
- **Manual Entry**: When you add persons or relationships

### Automated Collection
- **Conversation Processing**: Analysis of conversation content
- **Interaction Logging**: Recording of social interactions
- **Trust Calculation**: Automated trust score updates

## How We Use Your Information

We use the collected information for various purposes:
- **Social Awareness**: To provide context-aware responses
- **Trust Management**: To adapt behavior based on trust scores
- **Commitment Tracking**: To track promises and expectations
- **Relationship Mapping**: To understand social dynamics
- **Memory Integration**: To integrate with Hermes' memory system
- **User Experience**: To improve interaction quality

## Legal Basis for Processing (GDPR)

We process your information based on the following legal bases:
- **Consent**: You have given clear consent for processing
- **Legitimate Interest**: Our interest in providing social awareness
- **Contractual Necessity**: Processing necessary for service provision
- **Legal Obligation**: Compliance with legal requirements

## Information Sharing and Disclosure

### We Do Not Share Your Information
We do not sell, trade, or otherwise transfer your personal information to outside parties.

### Exceptions
We may disclose information only when:
- **Required by Law**: To comply with legal obligations
- **To Protect Rights**: To protect our rights or the rights of others
- **With Consent**: With your explicit consent

## Data Retention

### Retention Periods
- **Interaction Data**: 1 year (configurable)
- **Trust History**: Indefinitely
- **Commitment Data**: Until fulfilled or broken
- **Relationship Data**: Indefinitely
- **Audit Logs**: 90 days

### Data Deletion
You can request deletion of your data at any time using the `social_delete_person` command.

### Archival
Before deletion, data may be archived for legal or business purposes.

## Your Data Protection Rights

### Right to Access
You have the right to access your personal data. Use the `social_get_context` command to obtain a copy.

### Right to Rectification
You have the right to correct inaccurate personal data. Use the `social_update_person` command.

### Right to Erasure
You have the right to delete your personal data. Use the `social_delete_person` command.

### Right to Restriction
You have the right to restrict processing of your personal data. Use the `social_set_trust` command.

### Right to Data Portability
You have the right to receive your personal data in a structured format. Use the `social_export` command.

### Right to Object
You have the right to object to certain processing activities. Use the `social_object` command.

### Right to Withdraw Consent
You can withdraw your consent at any time by disabling the plugin or contacting us.

## Children's Privacy

### Age Restrictions
Our plugin is not intended for use by individuals under the age of 16. We do not knowingly collect personal information from children.

### COPPA Compliance
If we learn we have collected personal information from a child under 16, we will delete it immediately.

## International Data Transfers

### Local Processing
All data is processed locally on your server. No data is transferred internationally.

### No Cross-Border Transfers
We do not transfer personal data outside your jurisdiction.

## Security Measures

### Technical Measures
- **Encryption**: Optional database encryption
- **Access Controls**: File permissions, Hermes authentication
- **Audit Logging**: All database operations logged
- **Input Validation**: Basic sanitization
- **Error Handling**: Generic error messages

### Organizational Measures
- **Backup Procedures**: Daily automated backups
- **Update Management**: Regular security updates
- **Vulnerability Management**: Community monitoring
- **Incident Response**: Basic procedures documented

## Data Breach Notification

### Detection
We monitor for security breaches and will notify affected individuals within 72 hours of becoming aware of a breach.

### Notification Contents
- Description of the breach
- Categories of data affected
- Approximate number of individuals affected
- Likely consequences
- Measures taken to mitigate

### Notification Recipients
- **Authorities**: Within 72 hours (GDPR)
- **Individuals**: Within 72 hours if high risk
- **Media**: If required by law

## Changes to This Privacy Policy

### Updates
We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.

### Effective Date
The changes will be effective immediately upon posting on this page.

### Review
We encourage you to review this Privacy Policy periodically for any changes.

## Contact Us

### Questions or Comments
If you have questions or comments about this Privacy Policy, contact us at:

**Email**: privacy@hermes-agent.com  
**Mail**: Hermes AI Security Team, 123 Innovation Drive, San Francisco, CA 94105

### Data Protection Officer
For GDPR-related inquiries, contact our Data Protection Officer:

**DPO Email**: dpo@hermes-agent.com

### Complaints
If you have a complaint about our privacy practices, you can contact your local data protection authority.

## Additional Disclosures

### GDPR Compliance
We process personal data in accordance with the General Data Protection Regulation (GDPR). We have implemented appropriate technical and organizational measures to ensure compliance.

### CCPA Compliance
We comply with the California Consumer Privacy Act (CCPA). California residents have specific rights regarding their personal information.

### HIPAA Compliance
If processing health information, we comply with the Health Insurance Portability and Accountability Act (HIPAA).

---
**Last Updated**: {datetime.now().strftime("%B %d, %Y")}  
**Version**: 0.3.0  
**Plugin**: Social Tracking Plugin for Hermes AI
"""
    return privacy_policy

def main():
    print("Generating privacy policy...")
    policy = generate_privacy_policy()
    print(policy)
    return 0

if __name__ == "__main__":
    sys.exit(main())