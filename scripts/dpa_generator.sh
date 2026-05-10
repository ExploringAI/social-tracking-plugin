#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Data Processing Agreement Generator
This script generates a data processing agreement.
"""

import sys
from pathlib import Path
from datetime import datetime

def generate_dpa():
    """Generate a data processing agreement."""
    dpa = f"""# Data Processing Agreement

This Data Processing Agreement ("Agreement") is entered into on {datetime.now().strftime('%B %d, %Y')} between:

**Data Controller**: [Your Name/Company]  
Address: [Your Address]  
Contact: [Your Email]

And:

**Data Processor**: Hermes AI  
Address: 123 Innovation Drive, San Francisco, CA 94105  
Contact: dpo@hermes-agent.com

## 1. Definitions

1.1. "Data Protection Law" means any applicable data protection legislation, including GDPR, CCPA, HIPAA, and other privacy laws.

1.2. "Personal Data" means any information relating to an identified or identifiable natural person.

1.3. "Processing" means any operation performed on personal data.

1.4. "Data Subject" means an identified or identifiable natural person.

1.5. "Supervisory Authority" means an independent public authority responsible for monitoring data protection.

## 2. Scope of Processing

2.1. The Processor shall process Personal Data only on behalf of the Controller.

2.2. The processing activities include:
- Collecting personal data through user commands
- Processing personal data for social awareness
- Storing personal data in SQLite database
- Analyzing personal data for trust and relationship management
- Providing data subject rights mechanisms

2.3. The categories of data subjects include:
- Persons mentioned in conversations
- Users of the Hermes agent
- Potentially affected third parties

2.4. The categories of personal data processed include:
- Identifiers (names, person IDs)
- Personal characteristics (roles, interactions)
- Special category data (trust scores, relationships)
- Metadata (timestamps, event types)

2.5. The nature of processing includes:
- Collection
- Storage
- Use
- Disclosure (as required by law)
- Erasure

## 3. Data Controller Obligations

3.1. The Controller warrants that it has the legal basis to instruct the Processor to process the Personal Data.

3.2. The Controller shall provide accurate and complete instructions to the Processor.

3.3. The Controller shall inform the Processor of any specific data protection requirements.

3.4. The Controller shall obtain any necessary consents from Data Subjects.

## 4. Data Processor Obligations

4.1. The Processor shall process Personal Data only on documented instructions from the Controller.

4.2. The Processor shall implement appropriate technical and organizational measures to ensure a level of security appropriate to the risk.

4.3. The Processor shall not engage another processor without the Controller's prior written authorization.

4.4. The Processor shall assist the Controller in fulfilling data subject rights requests.

4.5. The Processor shall notify the Controller of a Personal Data breach without undue delay.

4.6. The Processor shall delete or return all Personal Data upon termination of this Agreement.

## 5. Security Measures

### 5.1 Technical Measures
- **Encryption**: Optional AES encryption for database
- **Access Control**: File permissions, Hermes authentication
- **Audit Logging**: All database operations logged
- **Input Validation**: Sanitization of user input
- **Error Handling**: Generic error messages
- **Backup Procedures**: Daily automated backups
- **Update Management**: Regular security updates

### 5.2 Organizational Measures
- **Data Protection Policy**: Documented procedures
- **Privacy by Design**: Implemented in development
- **Data Protection Impact Assessments**: Conducted regularly
- **Staff Training**: Annual privacy training
- **Incident Response**: Documented procedures

### 5.3 Specific Security Requirements
- **Encryption in Transit**: TLS for external communications
- **Encryption at Rest**: Available via SQLite encryption extensions
- **Access Controls**: Principle of least privilege
- **Multi-Factor Authentication**: Available for admin access
- **Vulnerability Management**: Regular security updates

## 6. Data Subject Rights

### 6.1 Right to Access
- **Mechanism**: `hermes social_get_context` command
- **Response Time**: Immediate
- **Format**: JSON or text summary

### 6.2 Right to Rectification
- **Mechanism**: `hermes social_update_person` command
- **Response Time**: Immediate
- **Process**: Update person record with new information

### 6.3 Right to Erasure
- **Mechanism**: `hermes social_delete_person` command
- **Response Time**: Immediate
- **Process**: Remove person and associated data

### 6.4 Right to Restriction
- **Mechanism**: `hermes social_set_trust` command
- **Response Time**: Immediate
- **Process**: Freeze trust score changes

### 6.5 Right to Data Portability
- **Mechanism**: `hermes social_export` command
- **Response Time**: Within 30 days
- **Format**: JSON or CSV

### 6.6 Right to Object
- **Mechanism**: `hermes social_object` command
- **Response Time**: Immediate
- **Process**: Opt-out of specific processing

## 7. Data Breach Notification

### 7.1 Notification Timeline
- **Authorities**: Within 72 hours (GDPR)
- **Individuals**: Within 60 days (HIPAA)
- **Controller**: Without undue delay

### 7.2 Notification Contents
- **Description**: Nature of the breach
- **Impact**: Categories of data affected
- **Remediation**: Steps taken
- **Contact**: Point of contact

### 7.3 Mitigation Measures
- **Containment**: Isolate affected systems
- **Eradication**: Remove threat, patch vulnerabilities
- **Recovery**: Restore from clean backup
- **Post-Incident**: Lessons learned, improvements

## 8. International Data Transfers

### 8.1 Transfer Restrictions
- **Cross-Border Transfers**: None
- **International Data Transfers**: None
- **Third-Country Transfers**: None
- **Safeguards**: Not applicable

### 8.2 Data Location
- **Processing Location**: Local server (where Hermes is installed)
- **Data Center**: User-controlled
- **Jurisdiction**: User's country

## 9. Subprocessors

### 9.1 Subprocessor List
- **None**: No subprocessors used

### 9.2 Subprocessor Obligations
- **Not Applicable**: No subprocessors

### 9.3 Controller Notification
- **Required**: Prior written authorization for any subprocessors
- **Compliance**: Subprocessors must meet same standards

## 10. Term and Termination

### 10.1 Term
This Agreement is effective until terminated by either party.

### 10.2 Termination for Cause
Either party may terminate this Agreement upon 30 days' written notice if the other party materially breaches these terms and fails to cure within the cure period.

### 10.3 Effects of Termination
Upon termination:
- Processor shall cease all processing
- Processor shall delete or return all Personal Data
- Controller shall destroy all copies
- Surviving provisions remain in effect

## 11. Governing Law

This Agreement shall be governed by the laws of the jurisdiction where the Controller is located, without regard to conflict of law principles.

## 12. Miscellaneous

### 12.1 Entire Agreement
This Agreement constitutes the entire agreement between the parties.

### 12.2 Amendments
Any amendments must be in writing and signed by both parties.

### 12.3 Severability
If any provision is held invalid, the remaining provisions remain in effect.

### 12.4 Waiver
Failure to enforce a provision is not a waiver of future enforcement.

### 12.5 Notices
All notices must be in writing and sent to the addresses above.

---
**Agreed**:

Data Controller: _________________________  
Date: _________________________  

Data Processor: Hermes AI  
Date: {datetime.now().strftime('%B %d, %Y')}
"""
    return dpa

def main():
    print("Generating data processing agreement...")
    dpa = generate_dpa()
    print(dpa)
    return 0

if __name__ == "__main__":
    sys.exit(main())