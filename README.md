# 🚀 SalesAI — 24/7 Autonomous Sales & Marketing Agent
> **Google Agentic Hackathon Submission — TaskMaster Track**  
> *Powered by Google Gemini 2.5 Flash, Google GenAI SDK & Google Search Grounding*

---

## 🌟 Overview & Problem Statement

Startups, solo founders, and modern B2B businesses struggle with outbound sales and marketing:
* **Manual prospecting is slow and expensive** (hours spent searching LinkedIn, Twitter, and company databases).
* **Cold outreach has low conversion** when it lacks hyper-personalized context.
* **Inbound replies go cold** when responses aren't instant or objections aren't handled with tailored proof points.
* **SDR teams cost \$80k+/year** and only work 8 hours a day.

**SalesAI changes the paradigm.** It is a **true 24/7 autonomous agent** that requires only your product or startup description. Once onboarded, SalesAI works non-stop in the background:
1. Deconstructs **Product DNA** and synthesizes an actionable **Ideal Customer Profile (ICP)**.
2. Continuously **prospects live companies and decision-makers** using **Google Search Grounding**.
3. Crafts **hyper-personalized multichannel campaigns** (Email Sequences, LinkedIn InMails, X/Twitter DMs).
4. Autonomously **handles inbound replies, scores intent (0–100), and overcomes objections**.
5. Manages a full **visual conversion pipeline (Kanban)** with zero manual babysitting.

---

## 🏆 Why SalesAI Wins the TaskMaster Track

The **TaskMaster Track** demands **long-horizon autonomous persistence**, not just a single-turn chatbot. SalesAI embodies this through:

```
                                  ┌──────────────────────────────────────────────────┐
                                  │             Flutter Mission Control              │
                                  │   (Live Agent Telemetry, Kanban, Autopilot)      │
                                  └─────────────────────────▲────────────────────────┘
                                                            │ REST + WebSockets
                                  ┌─────────────────────────▼────────────────────────┐
                                  │             Python FastAPI Backend               │
                                  │   (24/7 Event-Driven Loop + SQLite State)        │
                                  └─────────────────────────▲────────────────────────┘
                                                            │
  ┌─────────────────────────────────────────────────────────┴────────────────────────────────────────────────────────┐
  │                                     Google Gemini & Multi-Agent Engine                                            │
  ├────────────────────────┬─────────────────────────┬──────────────────────────┬────────────────────────────────────┤
  │    1. StrategyAgent    │   2. ProspectorAgent    │   3. CopywriterAgent     │          4. SdrAgent               │
  │ • Product DNA Analysis │ • Google Search Ground  │ • 3-Step Cold Sequences  │ • Intent Scoring (0-100)           │
  │ • ICP Synthesis        │ • Decision-Maker Leads  │ • LinkedIn / X DMs       │ • Objection Handling               │
  │ • Buyer Personas       │ • Pain Point Extraction │ • Value Hooks & CTAs     │ • Autonomous Counter-Responses     │
  └────────────────────────┴─────────────────────────┴──────────────────────────┴────────────────────────────────────┘
```

* **Continuous 24/7 Background Execution**: An asynchronous background engine autonomously checks lead inventory, prepares campaigns, schedules follow-ups, and adapts targeting strategy.
* **Dual Autonomy Modes**:
  * **AUTOPILOT Mode**: Full autonomous execution—discovers, writes, and dispatches campaigns continuously.
  * **COPILOT Mode**: Human-in-the-loop—prepares qualified prospects and copy in draft mode for 1-click human authorization.
* **Live WebSocket Telemetry**: Streams real-time thoughts, tool calls, and pipeline transitions directly to the Flutter Mission Control interface.

---

## 🛠️ Technology Stack

* **AI & Intelligence**:
  * [Google GenAI SDK (`google-genai`)](https://github.com/googleapis/python-genai)
  * **Gemini 2.5 Flash** (High-speed multi-agent generation & structured JSON outputs)
  * **Google Search Grounding** (Live company data and competitor intelligence)
* **Backend**:
  * Python 3.10+
  * FastAPI & Uvicorn
  * SQLAlchemy & SQLite (Persistent long-horizon state)
  * WebSockets (Real-time live telemetry stream)
  * APScheduler & AsyncIO (24/7 autonomous loop runner)
* **Frontend**:
  * **Flutter** (Cross-platform Desktop, Web, & Mobile)
  * Google Fonts (Outfit & Inter)
  * Custom Glassmorphic Cyber Dark Design System

---

## 🚀 Quickstart Guide

### 1. Prerequisites
* Python 3.10+
* Flutter 3.20+
* (Optional) Google Gemini API Key (A fallback simulation mode is built-in if no key is provided!)

### 2. Backend Setup
```bash
# Navigate to backend
cd backend

# Install dependencies
pip install -r requirements.txt

# (Optional) Set your Gemini API Key in .env
# GEMINI_API_KEY=your_key_here

# Run the FastAPI server
python -m backend.main
```
> The backend server starts at **`http://localhost:8000`** with interactive API docs at **`http://localhost:8000/docs`**.

### 3. Frontend Setup (Flutter)
```bash
# In a new terminal, navigate to frontend
cd frontend

# Get Flutter dependencies
flutter pub get

# Run on Chrome Web or Windows Desktop
flutter run -d chrome
# or: flutter run -d windows
```

---

## 🎯 1-Click Demo Walkthrough (For Hackathon Judges)

1. Open the Flutter app or navigate to `http://localhost:8000/docs`.
2. Click **"1-Click Demo Seed"** on the top right.
3. SalesAI immediately loads **DevPulse AI** (or enter your own startup details in the **Product DNA** tab).
4. Watch the **Live Telemetry Terminal**:
   * `StrategyAgent` analyzes Product DNA and constructs the ICP.
   * `ProspectorAgent` discovers verified enterprise decision-makers.
   * `CopywriterAgent` produces 3-step personalized outreach sequences.
   * `SdrAgent` autonomously evaluates inbound replies and handles objections.
5. Click on any lead in the **Pipeline Kanban** to view the full prospect profile, AI reasoning, and generated multi-channel copy!

---

## 👥 Authors
Built for the **Google Agentic Hackathon** (TaskMaster Track).
