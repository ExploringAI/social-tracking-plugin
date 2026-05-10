#!/usr/bin/env python3
"""Setup configuration for hermes-social-tracking-plugin."""

from setuptools import setup, find_packages

setup(
    name="hermes-social-tracking-plugin",
    version="0.3.0",
    description="Human-like social awareness layer for Hermes AI agents",
    long_description=open("README.md", "r", encoding="utf-8").read(),
    long_description_content_type="text/markdown",
    author="Marko Polo",
    author_email="marko@example.com",
    url="https://github.com/yourusername/hermes-social-tracking-plugin",
    packages=find_packages(),
    package_data={
        "social_tracking": [
            "plugin.yaml",
            "README.md",
            "*.py",
            "core/*.py",
            "advanced/*.py",
        ],
    },
    install_requires=[
        "pydantic>=1.10.0",
    ],
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Environment :: Console",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Topic :: Software Development :: Libraries",
        "Topic :: Artificial Intelligence",
    ],
    python_requires=">=3.10",
)