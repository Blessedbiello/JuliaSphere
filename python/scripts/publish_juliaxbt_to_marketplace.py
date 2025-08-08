#!/usr/bin/env python3
"""
juliaXBT Marketplace Publishing Script

This script creates and publishes the juliaXBT blockchain investigation agent 
to the JuliaSphere marketplace, demonstrating the complete agent lifecycle:
creation -> marketplace listing -> user deployment.

Usage:
    python scripts/publish_juliaxbt_to_marketplace.py
"""

import juliaos
import json
import sys
from datetime import datetime

# Configuration
HOST = "http://127.0.0.1:8052/api/v1"
AGENT_ID = "juliaxbt-investigator"
AGENT_NAME = "juliaXBT - Blockchain Investigation Agent"
AGENT_DESCRIPTION = """
Advanced blockchain forensics agent conducting comprehensive investigations in the style of juliaXBT.

Capabilities:
• Multi-hop transaction tracing across Solana blockchain
• Mixer and privacy protocol detection
• Social media intelligence gathering
• Compliance violation assessment  
• Automated evidence compilation and reporting
• Investigation thread generation for community awareness

Perfect for detecting suspicious wallet activity, tracking stolen funds, 
identifying money laundering patterns, and conducting due diligence investigations.
""".strip()

# Agent Blueprint Configuration
AGENT_BLUEPRINT = juliaos.AgentBlueprint(
    tools=[
        # Solana blockchain RPC tool
        juliaos.ToolBlueprint(
            name="solana_rpc",
            config={
                "rpc_url": "https://api.mainnet-beta.solana.com",
                "timeout_seconds": 30
            }
        ),
        # Transaction tracing tool
        juliaos.ToolBlueprint(
            name="transaction_tracer",
            config={
                "rpc_url": "https://api.mainnet-beta.solana.com",
                "max_hops": 7,
                "timeout_seconds": 60,
                "min_transfer_amount": 0.001
            }
        ),
        # Mixer detection tool
        juliaos.ToolBlueprint(
            name="mixer_detector",
            config={
                "rpc_url": "https://api.mainnet-beta.solana.com",
                "tornado_cash_addresses": [
                    "JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4",
                    "whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc"
                ],
                "samourai_addresses": [],
                "mixer_confidence_threshold": 0.7,
                "analysis_depth": 5,
                "timeout_seconds": 30
            }
        ),
        # Twitter research tool
        juliaos.ToolBlueprint(
            name="twitter_research",
            config={
                "bearer_token": "demo-twitter-bearer-token",
                "api_base_url": "https://api.twitter.com/2",
                "max_results_per_request": 50,
                "timeout_seconds": 30,
                "include_metrics": True
            }
        ),
        # Investigation thread generator
        juliaos.ToolBlueprint(
            name="thread_generator",
            config={
                "api_key": "demo-key-placeholder",
                "model_name": "models/gemini-1.5-pro",
                "temperature": 0.8,
                "max_output_tokens": 2048,
                "juliaxbt_style": True
            }
        )
    ],
    strategy=juliaos.StrategyBlueprint(
        name="juliaxbt_investigation",
        config={
            "max_investigation_depth": 7,
            "auto_publish_threads": False,  # Manual control for demo
            "investigation_priority_threshold": "MEDIUM",
            "enable_social_media_research": True,
            "evidence_confidence_threshold": 0.7
        }
    ),
    trigger=juliaos.TriggerConfig(
        type="webhook",
        params={
            "path": "/investigate",
            "method": "POST"
        }
    )
)

# Marketplace Metadata
MARKETPLACE_METADATA = {
    "category": "Blockchain Analytics",
    "tags": [
        "blockchain", 
        "investigation", 
        "forensics", 
        "solana", 
        "security", 
        "juliaXBT", 
        "compliance",
        "aml",
        "defi",
        "mixer-detection"
    ],
    "pricing_model": "free",
    "price_amount": 0.0,
    "currency": "USD",
    "featured_image_url": "https://example.com/juliaxbt-logo.png",  # TODO: Add actual image
    "documentation": """
# juliaXBT Investigation Agent

## Overview
The juliaXBT Investigation Agent conducts comprehensive blockchain forensics investigations, combining on-chain analysis with social media intelligence to provide complete investigative reports.

## Key Features

### Blockchain Analysis
- **Multi-hop Transaction Tracing**: Follow funds across up to 7 transaction hops
- **Mixer Detection**: Identify interactions with known mixing services and privacy protocols
- **Pattern Analysis**: Detect suspicious transaction patterns and behaviors
- **Volume Analysis**: Track total volumes and identify large movements

### Social Media Intelligence
- **Twitter Research**: Search for mentions, discussions, and community sentiment
- **Profile Analysis**: Investigate suspicious accounts and coordinated behavior
- **Timeline Correlation**: Match blockchain activity with social media posts
- **Evidence Compilation**: Automatically gather and organize social evidence

### Investigation Output
- **Risk Assessment**: Comprehensive risk scoring and compliance evaluation
- **Evidence Package**: Organized collection of all findings with timestamps
- **Investigation Reports**: Detailed analysis with actionable recommendations
- **Thread Generation**: Professional investigation threads for community awareness

## Usage Examples

### Basic Investigation
```python
investigation_input = {
    "target_address": "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1",
    "investigation_type": "full",
    "suspected_activity": "mixer",
    "urgency_level": "normal"
}

result = agent.call_webhook(investigation_input)
```

### Quick Blockchain Analysis
```python
investigation_input = {
    "target_address": "ABC123...",
    "investigation_type": "blockchain_only",
    "suspected_activity": "hack",
    "urgency_level": "high"
}

result = agent.call_webhook(investigation_input)
```

### Social Media Focus
```python
investigation_input = {
    "target_address": "XYZ789...",
    "investigation_type": "social_only",
    "suspected_activity": "scam",
    "urgency_level": "normal"
}

result = agent.call_webhook(investigation_input)
```

## Investigation Types

- **full**: Complete blockchain + social media investigation (recommended)
- **quick**: Fast blockchain analysis with basic reporting
- **blockchain_only**: Deep blockchain analysis without social media
- **social_only**: Social media research without blockchain tracing

## Suspected Activities

- **mixer**: Money laundering through mixing services
- **scam**: Fraudulent schemes and rug pulls
- **hack**: Stolen funds and exploits
- **laundering**: General money laundering activity
- **unknown**: General suspicious activity investigation

## Output Format

The agent returns comprehensive investigation results including:

```json
{
    "investigation_id": "INV_123456",
    "target_address": "...",
    "final_assessment": {
        "risk_level": "HIGH|MEDIUM|LOW|MINIMAL",
        "key_findings": [...],
        "recommended_actions": [...]
    },
    "blockchain_analysis": {
        "transaction_traces": [...],
        "mixer_interactions": {...},
        "total_volume": 0.0,
        "addresses_visited": [...]
    },
    "social_media_intelligence": {
        "related_discussions": [...],
        "suspicious_accounts": [...],
        "social_risk_indicators": [...]
    },
    "evidence_package": {
        "blockchain_evidence": [...],
        "social_evidence": [...],
        "timeline": [...],
        "supporting_documents": [...]
    },
    "compliance_assessment": {
        "violations": [...],
        "risk_score": 0.0,
        "compliance_level": "..."
    }
}
```

## Requirements

### Environment Variables
- `GEMINI_API_KEY`: Required for LLM-powered analysis
- `TWITTER_BEARER_TOKEN`: Optional, enhances social media research
- `SOLANA_RPC_URL`: Optional, defaults to public RPC

### Dependencies
All dependencies are automatically managed by the JuliaSphere platform.

## Support
For technical support or feature requests, contact the JuliaSphere community or create an issue in the project repository.
""",
    "example_usage": {
        "basic_investigation": {
            "target_address": "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1",
            "investigation_type": "full",
            "suspected_activity": "mixer",
            "urgency_level": "normal"
        },
        "quick_scan": {
            "target_address": "11111111111111111111111111111112",
            "investigation_type": "quick",
            "suspected_activity": "unknown",
            "urgency_level": "normal"
        }
    }
}

def main():
    """Main execution function"""
    print("🔍 juliaXBT Marketplace Publishing Script")
    print("=" * 60)
    print(f"📅 Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()

    try:
        # Establish connection to JuliaSphere backend
        print("🔌 Connecting to JuliaSphere backend...")
        with juliaos.JuliaOSConnection(HOST) as conn:
            print(f"✅ Connected to: {HOST}")
            
            # Check for existing agent and handle cleanup
            try:
                print(f"🔍 Checking for existing agent '{AGENT_ID}'...")
                existing_agent = juliaos.Agent.load(conn, AGENT_ID)
                print(f"⚠️ Agent '{AGENT_ID}' already exists. Deleting for clean setup...")
                existing_agent.delete()
                print("🗑️ Existing agent deleted successfully")
            except Exception as e:
                print(f"ℹ️ No existing agent found (expected): {AGENT_ID}")

            # List current agents for context
            print("\n📋 Current agents in system:")
            current_agents = conn.list_agents()
            for agent_info in current_agents:
                print(f"  - {agent_info}")
            
            print(f"\n🤖 Creating juliaXBT Investigation Agent...")
            print(f"   ID: {AGENT_ID}")
            print(f"   Name: {AGENT_NAME}")
            print(f"   Tools: {len(AGENT_BLUEPRINT.tools)}")
            print(f"   Strategy: {AGENT_BLUEPRINT.strategy.name}")
            
            # Create the agent
            agent = juliaos.Agent.create(
                conn, 
                AGENT_BLUEPRINT, 
                AGENT_ID, 
                AGENT_NAME, 
                AGENT_DESCRIPTION
            )
            print("✅ Agent created successfully!")
            
            # Set agent to running state
            print("▶️ Setting agent state to RUNNING...")
            agent.set_state(juliaos.AgentState.RUNNING)
            print("✅ Agent is now active and ready for investigations")
            
            # Verify agent configuration
            print("\n🔧 Agent Configuration Verification:")
            agent_info = agent.get_info()
            print(f"   State: {agent_info.get('state', 'unknown')}")
            print(f"   Tools configured: {len(agent_info.get('tools', []))}")
            print(f"   Strategy: {agent_info.get('strategy_name', 'unknown')}")
            
            # TODO: Publish to marketplace
            # Note: This would require the marketplace API to be implemented
            print("\n🏪 Marketplace Publishing:")
            print("   📝 Agent ready for marketplace publishing")
            print("   🔗 Marketplace metadata prepared")
            print("   ⏳ TODO: Implement marketplace publishing API call")
            print()
            
            # Display marketplace metadata
            print("📋 Marketplace Metadata Summary:")
            print(f"   Category: {MARKETPLACE_METADATA['category']}")
            print(f"   Tags: {', '.join(MARKETPLACE_METADATA['tags'][:5])}... ({len(MARKETPLACE_METADATA['tags'])} total)")
            print(f"   Pricing: {MARKETPLACE_METADATA['pricing_model']} (${MARKETPLACE_METADATA['price_amount']})")
            print(f"   Documentation: {len(MARKETPLACE_METADATA['documentation'])} characters")
            
            print("\n✨ Agent Setup Complete!")
            print("🔍 You can now test the agent with sample investigations")
            print(f"📞 Agent webhook endpoint: {HOST}/agents/{AGENT_ID}/webhook")
            
            # Display sample investigation
            print("\n📖 Sample Investigation Command:")
            sample_investigation = {
                "target_address": "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1",
                "investigation_type": "full", 
                "suspected_activity": "mixer",
                "urgency_level": "normal"
            }
            print("   agent.call_webhook({")
            for key, value in sample_investigation.items():
                print(f'       "{key}": "{value}",')
            print("   })")
            
            return 0
            
    except Exception as e:
        print(f"❌ Error during agent creation/publishing:")
        print(f"   {str(e)}")
        print(f"\n💡 Troubleshooting:")
        print(f"   1. Ensure JuliaSphere backend is running: julia --project=. run_server.jl")
        print(f"   2. Check environment variables in backend/.env")
        print(f"   3. Verify all investigation tools are registered in backend")
        print(f"   4. Confirm network connectivity to {HOST}")
        return 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)