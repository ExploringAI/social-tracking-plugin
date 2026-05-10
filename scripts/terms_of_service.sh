#!/usr/bin/env python3
"""
Hermes Social Tracking Plugin - Terms of Service Generator
This script generates terms of service.
"""

import sys
from pathlib import Path
from datetime import datetime

def generate_terms_of_service():
    """Generate terms of service."""
    terms = f"""# Social Tracking Plugin Terms of Service

Last Updated: {datetime.now().strftime("%B %d, %Y")}
Plugin Version: 0.3.0

## Acceptance of Terms

By using the Social Tracking Plugin for Hermes AI ("Plugin"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, you must not use the Plugin.

## Description of Service

The Social Tracking Plugin is an extension for the Hermes AI agent that provides social awareness capabilities, including:
- Person tracking and management
- Trust scoring and management
- Commitment and promise tracking
- Relationship mapping
- Social context injection

## License Grant

Subject to these Terms, we grant you a limited, non-exclusive, non-transferable, revocable license to use the Plugin for your internal business purposes.

## Restrictions

You agree not to:
- Modify, adapt, or hack the Plugin
- Remove or alter any proprietary notices
- Use the Plugin for illegal purposes
- Interfere with or disrupt the Plugin
- Attempt to gain unauthorized access
- Reverse engineer or decompile the Plugin
- Use the Plugin to compete with us

## User Responsibilities

### Data Management
You are responsible for:
- Ensuring you have rights to process personal data
- Obtaining necessary consents
- Complying with data protection laws
- Securing your data
- Backing up your data

### Compliance
You must comply with:
- All applicable laws and regulations
- This Terms of Service
- Plugin documentation
- Data protection laws (GDPR, CCPA, HIPAA, etc.)

### Security
You are responsible for:
- Securing your server
- Protecting database credentials
- Implementing access controls
- Monitoring for security breaches

## Fees and Payment

### Free Software
The Plugin is provided free of charge under the MIT License.

### Optional Services
Fees may apply for optional services such as:
- Premium support
- Custom development
- Training services
- Consulting services

All fees are non-refundable unless required by law.

## Term and Termination

### Term
These Terms are effective until terminated by you or us.

### Termination for Cause
We may terminate these Terms if you:
- Breach these Terms materially
- Fail to cure within 30 days of notice
- Violate applicable laws

### Termination for Convenience
You may terminate these Terms at any time by uninstalling the Plugin.

### Effects of Termination
Upon termination:
- License terminates immediately
- You must cease all use
- You must destroy all copies
- Surviving provisions remain in effect

## Disclaimer of Warranties

THE PLUGIN IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND. WE DISCLAIM ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.

## Limitation of Liability

IN NO EVENT WILL WE BE LIABLE FOR:
- INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES
- LOSS OF PROFITS, REVENUE, DATA, OR USE
- DAMAGES EXCEEDING FEES PAID IN PAST 12 MONTHS
- TOTAL LIABILITY EXCEEDING $100

## Indemnification

You agree to indemnify and hold us harmless from any claims, damages, or expenses arising from your use of the Plugin or violation of these Terms.

## Intellectual Property

### Our Intellectual Property
We retain all rights, title, and interest in the Plugin, including all intellectual property rights.

### Your Intellectual Property
You retain all rights to your data and modifications you make to the Plugin.

### Open Source Components
The Plugin may include open source components with separate licenses.

## Data Processing

### Your Data Responsibilities
You are responsible for ensuring you have the right to process personal data using the Plugin.

### Data Processing Addendum
For GDPR compliance, a Data Processing Addendum may be required.

### Data Location
Data is processed on your server. You control data location.

## Changes to Terms

### Modifications
We may modify these Terms at any time. Continued use constitutes acceptance.

### Notification
We will notify you of material changes via:
- GitHub repository
- Email (if provided)
- Plugin documentation

### Review
You are responsible for regularly reviewing these Terms.

## Governing Law

These Terms are governed by the laws of the jurisdiction where you reside, without regard to conflict of law principles.

## Dispute Resolution

### Informal Resolution
Contact us first to resolve disputes.

### Arbitration
If informal resolution fails, disputes will be resolved by binding arbitration.

### Class Action Waiver
You may not bring a class action against us.

## Miscellaneous

### Entire Agreement
These Terms constitute the entire agreement between us.

### Severability
If any provision is invalid, the remaining provisions remain in effect.

### Waiver
Failure to enforce a provision is not a waiver.

### Assignment
You may not assign these Terms without our consent.

### Force Majeure
We are not liable for delays caused by events beyond our control.

## Contact Information

### Questions
For questions about these Terms, contact:

**Email**: legal@hermes-agent.com  
**Mail**: Hermes AI Legal Department, 123 Innovation Drive, San Francisco, CA 94105

### Reporting Violations
Report violations to: violations@hermes-agent.com

---
**Last Updated**: {datetime.now().strftime("%B %d, %Y")}  
**Plugin Version**: 0.3.0  
**Effective Date**: {datetime.now().strftime("%B %d, %Y")}
"""
    return terms

def main():
    print("Generating terms of service...")
    terms = generate_terms_of_service()
    print(terms)
    return 0

if __name__ == "__main__":
    sys.exit(main())