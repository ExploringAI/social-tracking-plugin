#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Data Subject Request Procedure
This script generates a data subject request procedure.
"""

import sys
from pathlib import Path
from datetime import datetime

def generate_data_subject_request_procedure():
    """Generate a data subject request procedure."""
    procedure = f"""# Social Tracking Plugin Data Subject Request Procedure

Effective Date: {datetime.now().strftime('%B %d, %Y')}
Plugin Version: 0.3.0

## 1. Introduction

### 1.1 Purpose
This procedure outlines how to handle data subject requests under data protection laws such as GDPR, CCPA, and HIPAA for the Social Tracking Plugin for Hermes AI.

### 1.2 Scope
This procedure applies to all requests received from data subjects regarding their personal data processed by the Social Tracking Plugin.

## 2. Types of Requests

### 2.1 Right to Access
- **Command**: `hermes social_get_context`
- **Response Time**: Immediate
- **Format**: JSON or text summary
- **Scope**: All data about the person

### 2.2 Right to Rectification
- **Command**: `hermes social_update_person`
- **Response Time**: Immediate
- **Process**: Update person record with new information
- **Limitations**: Cannot change person ID

### 2.3 Right to Erasure
- **Command**: `hermes social_delete_person`
- **Response Time**: Immediate
- **Process**: Remove person and associated data
- **Exceptions**: May retain anonymized data for analytics

### 2.4 Right to Restriction
- **Command**: `hermes social_set_trust`
- **Response Time**: Immediate
- **Process**: Freeze trust score changes
- **Scope**: Limited to trust processing

### 2.5 Right to Data Portability
- **Command**: `hermes social_export`
- **Response Time**: Within 30 days
- **Format**: JSON or CSV
- **Scope**: All data about the person

### 2.6 Right to Object
- **Command**: `hermes social_object`
- **Response Time**: Immediate
- **Process**: Opt-out of specific processing
- **Scope**: Limited to specified processing

## 3. Request Handling Process

### 3.1 Request Receipt
**Methods of Submission**:
- Direct command to Hermes
- Email to dpo@hermes-agent.com
- Web form (if available)
- Written letter

**Required Information**:
- Full name of data subject
- Email address (for verification)
- Description of requested action
- Any relevant context

### 3.2 Verification
**Identity Verification**:
1. Check provided email against stored data
2. Verify through security questions if needed
3. Confirm person exists in database
4. Document verification steps

**Authority Verification**:
1. Confirm requestor is data subject
2. Check for legal authorization (if third party)
3. Verify parent/guardian status (for children's data)

### 3.3 Request Assessment
**Eligibility Check**:
- Confirm request falls within data subject rights
- Check for excessive frequency or volume
- Assess if request is manifestly unfounded
- Determine if fee is applicable

**Scope Determination**:
- Identify specific data to be provided
- Determine format of response
- Assess any third-party data involved
- Check for any legal exemptions

### 3.4 Response Preparation

#### Access Request (`social_get_context`)
```bash
# Execute command
hermes social_get_context person=[name]

# Format response
Provide summary in clear, understandable format
Include all relevant personal data
Explain processing purposes
Include retention periods
Provide contact information for complaints
```

#### Rectification Request (`social_update_person`)
```bash
# Verify current data
hermes social_get_person name=[name]

# Update information
hermes social_update_person name=[name] roles=[new_roles] kind=[new_kind]

# Confirm update
hermes social_get_person name=[name]
```

#### Erasure Request (`social_delete_person`)
```bash
# Verify person exists
hermes social_get_person name=[name]

# Delete person
hermes social_delete_person name=[name]

# Confirm deletion
Check database for remaining records
```

#### Restriction Request (`social_set_trust`)
```bash
# Set trust to neutral
hermes social_set_trust person=[name] trust=0.5

# Verify restriction
hermes social_get_person name=[name]
```

#### Portability Request (`social_export`)
```bash
# Generate export
hermes social_export person=[name] format=json > export.json

# Verify export completeness
Check that all personal data included
Ensure proper formatting
```

#### Objection Request (`social_object`)
```bash
# Record objection
Add to system notes that person objects to processing

# Assess basis for objection
Review grounds for objection
Determine if processing should cease

# Implement measures
Adjust processing as required
```

### 3.5 Response Delivery

#### Timeline Requirements
- **Access Requests**: Immediate (via command)
- **Rectification**: Immediate
- **Erasure**: Within 1 month (immediate via command)
- **Restriction**: Immediate
- **Portability**: Within 30 days
- **Objection**: Immediate

#### Delivery Methods
- **Electronic Delivery**: Email, secure portal
- **In Writing**: Physical mail if requested
- **Through Hermes**: Direct command response

#### Content Requirements
- **Clear Language**: Use understandable language
- **Comprehensive**: Include all requested data
- **Free of Charge**: No fee for reasonable requests
- **Contact Information**: Provide DPO contact

### 3.6 Fee Assessment
**No Fee Required When**:
- Request is reasonable
- Data is readily accessible
- Processing is not excessive

**Fee May Be Charged When**:
- Request is manifestly unfounded
- Request is excessive (repetitive or complex)
- Administrative costs exceed normal threshold

**Fee Calculation**:
- Based on administrative costs
- Transparent and justified
- Notify requester in advance

## 4. Documentation and Record Keeping

### 4.1 Request Documentation
- **Request Log**: Date, method, requester information
- **Verification Records**: Identity verification steps
- **Assessment Notes**: Eligibility determination
- **Response Details**: Actions taken, data provided
- **Communication Records**: All correspondence

### 4.2 Retention Periods
- **Request Logs**: 3 years
- **Response Records**: 3 years
- **Assessment Notes**: 3 years
- **Legal Hold Requests**: 7 years

### 4.3 Record Contents
- **Request Details**: Nature of request, date received
- **Identity Verification**: Methods used, results
- **Actions Taken**: Steps performed, date, responsible person
- **Outcome**: Resolution, data provided, fees charged
- **Legal Basis**: Justification for actions

## 5. Third-Party Requests

### 5.1 Authorized Agents
**Requirements**:
- Written authorization from data subject
- Proof of identity for both parties
- Clear description of requested action

**Process**:
1. Verify written authorization
2. Confirm identity of both parties
3. Treat as direct request from data subject
4. Document authorization on file

### 5.2 Legal Requests
**Law Enforcement**:
- Court order or subpoena required
- Verify authenticity of request
- Produce only required data
- Notify data subject when permitted

**Government Agencies**:
- Official request on letterhead
- Verify agency identity
- Produce data as legally required
- Document request and response

## 6. Special Categories of Data

### 6.1 Health Data (HIPAA)
**Additional Requirements**:
- Business Associate Agreement in place
- Minimum necessary standard
- Encryption requirements
- Breach notification procedures
- Accounting of disclosures

**Processing**:
- Extra verification for health data requests
- Additional security measures
- Specific retention periods
- Special disposal requirements

### 6.2 Children's Data (COPPA)
**Requirements**:
- Parental consent verification
- Age verification procedures
- Parental access rights
- Data deletion upon request
- Limited data collection

**Processing**:
- Extra verification for children's data
- Parental consent checks
- Age-appropriate communication
- Enhanced security measures

## 7. Timeframes and Deadlines

### 7.1 Standard Timeframes
- **Access Requests**: Immediate (via command)
- **Rectification**: Immediate
- **Erasure**: Within 1 month
- **Restriction**: Immediate
- **Portability**: Within 30 days
- **Objection**: Immediate

### 7.2 Extensions
**Additional Time**:
- Up to 2 additional months for complex requests
- Notify requester within 1 month of receipt
- Explain reason for extension

**Notification Requirements**:
- Inform requester of extension
- Provide justification
- Give updated timeline
- Maintain communication

### 7.3 Fees
**No Fee Required**:
- Most data subject requests
- Reasonable frequency
- Accessible format

**Fee Permissible**:
- Excessive requests
- Complex data retrieval
- Additional copies beyond first

## 8. Refusal of Requests

### 8.1 Valid Refusal Grounds
- **Manifestly Unfounded**: Lack of sincerity or purpose
- **Excessive**: Repetitive or overly broad
- **Legal Exemptions**: Data subject to legal privilege
- **Third Party Impact**: Would harm other individuals

### 8.2 Refusal Procedure
1. **Assess Grounds**: Determine valid reason for refusal
2. **Notify Requestor**: Inform of refusal and reasons
3. **Explain Rights**: Inform of right to complain
4. **Document Decision**: Record rationale and process

### 8.3 Notification of Refusal
**Required Contents**:
- Reasons for not taking action
- Data subject's right to complain to supervisory authority
- Right to seek judicial remedy
- Information about challenges to legal basis

## 9. Review and Appeals

### 9.1 Internal Review
- [ ] Review request handling procedures annually
- [ ] Assess compliance with data protection laws
- [ ] Update forms and procedures as needed
- [ ] Train staff on changes

### 9.2 Supervisory Authority Review
- [ ] Cooperate with regulatory investigations
- [ ] Provide documentation as requested
- [ ] Respond to inquiries promptly
- [ ] Implement regulatory guidance

### 9.3 Judicial Review
- [ ] Defend decisions in court
- [ ] Respond to legal challenges
- [ ] Update practices based on rulings
- [ ] Maintain legal counsel

## 10. Training and Awareness

### 10.1 Staff Training
- [ ] Annual privacy training
- [ ] Security awareness programs
- [ ] Incident response drills
- [ ] Data handling procedures

### 10.2 Documentation
- [ ] Training materials
- [ ] Attendance records
- [ ] Competency assessments
- [ ] Refresher training

## 11. Monitoring and Reporting

### 11.1 Regular Monitoring
- [ ] Monthly compliance checks
- [ ] Quarterly risk assessments
- [ ] Annual security assessment
- [ ] Biannual privacy assessments

### 11.2 Reporting
- [ ] Internal reports to management
- [ ] Regulatory reports as required
- [ ] Incident reports
- [ ] Audit findings

## 12. Contact Information

### 12.1 Data Protection Officer
**Email**: dpo@hermes-agent.com  
**Mail**: Hermes AI Security Team, 123 Innovation Drive, San Francisco, CA 94105

### 12.2 Support
**Email**: support@hermes-agent.com  
**GitHub**: https://github.com/yourusername/hermes-social-tracking-plugin/issues

---
**Note**: This is a living document. Review and update regularly.
"""
    return data_subject_request_procedure

def main():
    print("Generating data subject request procedure...")
    procedure = generate_data_subject_request_procedure()
    print(procedure)
    return 0

if __name__ == "__main__":
    sys.exit(main())