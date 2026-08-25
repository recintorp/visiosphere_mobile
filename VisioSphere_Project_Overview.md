# VisioSphere: Project Overview

**A Web and Mobile Monitoring and Management System for Elderly Residents in Care Facilities Using Image Processing**

Developed by: MERGE-IT | National University – College of Computing and Information Technologies
Implementation Site: Golden Acres Home for the Aged, National Capital Region
Capstone Adviser: Prof. Julie Anne A. Crystal | January 2026

---

## The Problem

Elderly care facilities face a persistent safety challenge: nurses cannot monitor all residents at the same time, and incidents — particularly falls — can go undetected for critical minutes between routine rounds. While CCTV cameras are already installed in most facilities, they provide no safety value unless someone is actively watching every feed, which is rarely feasible.

In the Philippines, this is especially pressing. Studies show that up to 32.1% of elderly patients in care facilities experience falls over a 10-month period. At Golden Acres, residents are spread across multiple houses and common areas, making continuous manual monitoring effectively impossible.

---

## What VisioSphere Does

VisioSphere transforms existing CCTV infrastructure into an intelligent, automated safety monitoring system. Rather than replacing cameras or requiring residents to wear devices, the system analyzes live camera feeds using AI to detect safety incidents automatically — and delivers alerts to staff in under two seconds.

The system requires no action from residents. Cameras remain in common areas only (hallways, dining rooms, living rooms). Detection is based on body movement, not facial recognition, keeping the system fully compliant with the Data Privacy Act of 2012 and DSWD operational guidelines.

---

## Core Capabilities

**AI Incident Detection**
The system uses YOLOv11-Pose (a state-of-the-art pose estimation model) combined with OpenCV to continuously analyze video frames. For each person visible on camera, it tracks 17 skeletal keypoints — shoulders, elbows, hips, knees, ankles — and monitors their movement in real time.

Three types of incidents are detected automatically:

- **Fall Detection** — identifies uncontrolled falls by measuring the speed of torso angle change. A fall is confirmed only if the body dropped at more than 45°/second over 2.5 seconds, and the fallen posture holds across at least 3 consecutive frames. This prevents false alarms from residents simply lying down. If a person remains on the floor for over 30 seconds, a re-alert fires every 60 seconds until the situation is resolved.

- **Agitation Risk Detection** — monitors body posture for distress signals such as hands on head, raised elbows, and rapid wrist oscillation. An alert is only issued if distress signals remain elevated for at least 20 seconds, avoiding false alarms from brief movements.

- **Inactivity Detection** — tracks the torso's center point over time. If a resident remains completely still for 60 or more seconds, an emergency alert is issued. If the resident also appears slumped (torso leaning more than 40° from vertical), the alert is labeled "Inactive Posture" to give responding nurses an immediate picture of what to expect.

All alerts are delivered to staff dashboards via Socket.IO with a network latency of under 100 milliseconds.

---

## Who Uses It

**Administrators** have full system access: they can view live CCTV feeds to visually verify incidents, manage resident records and staff accounts, configure AI sensitivity settings, and review the complete audit trail of all system activity.

**Nurses** receive a text-based Emergency Log on their dashboard and mobile app. When an alert fires — "Fall Detected in Dining Hall" — nurses are directed to the location immediately without needing to watch continuous video.

**Guardians** (family members) use the mobile companion app to receive push notifications for critical incidents and to view daily assessments, health summaries, and reports about their loved one. Guardians do not have access to live video feeds, preserving the privacy of all residents.

---

## System Components

**Web Dashboard (React.js)**
The primary interface for administrators and nurses. Key modules include:
- Real-time dashboard with resident headcount, active cameras, and alert summaries
- Live CCTV monitoring with AI overlay (admin only)
- Daily health assessment documentation with rich content blocks (text, checklists, charts, images, file attachments) and comment threads
- Incident management and reporting
- User account management with role-based access control
- Audit trail and system activity logs
- System configuration and AI sensitivity controls

**Mobile Companion App (Flutter – Android & iOS)**
The Guardian App allows family members to stay informed from anywhere. It delivers push notifications via Firebase Cloud Messaging, ensuring alerts reach guardians even when the app is closed. Nurses and administrators can also use the mobile app to receive alerts and view resident information on the go.

**AI Core (Python + YOLOv11)**
Runs on-premise at the facility on a server with a dedicated GPU. Processes RTSP streams from existing IP cameras, performs all pose estimation locally, and sends only event metadata (not raw video) to the backend — minimizing bandwidth use and preserving privacy.

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| AI Engine | Python, YOLOv11-Pose, OpenCV, BoT-SORT |
| Backend API | Node.js / Express.js + MongoDB Atlas |
| Web Frontend | React.js (Vite), deployed on Vercel |
| Mobile App | Flutter (Android & iOS), deployed on Heroku |
| Real-Time Alerts | Socket.IO |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| File Storage | AWS S3 |

---

## Hardware Requirements

| Component | Specifications |
|-----------|---------------|
| Processing Server | Intel Core i5 / AMD Ryzen 5 or higher · 16–24 GB RAM (8 GB minimum) · NVIDIA GPU with CUDA support (GTX 1050 or higher) · 256 GB SSD · Windows 10/11 or Ubuntu 22.04 LTS |
| IP Cameras | 720p HD / 1080p FHD · RTSP / ONVIF protocol support · Wi-Fi or Ethernet · Night vision (infrared) capability |
| Mobile Device (Staff & Guardians) | Android 10.0 or higher · 4 GB RAM minimum · 4G/5G or Wi-Fi · 720p display or higher |

The processing server runs the AI engine on-premise inside the facility. A dedicated NVIDIA GPU is required to sustain real-time YOLOv11 inference at the target frame rate. The system is designed to work with standard off-the-shelf IP cameras already installed in most care facilities — no proprietary sensors or specialized hardware are needed.

---

## Privacy and Compliance

- Cameras are installed in common areas only — not in bedrooms, bathrooms, or any private space
- Detection is based solely on skeletal body movement; no facial recognition or identity storage
- Role-based access control ensures each user sees only what their role permits
- All data handling aligns with the Data Privacy Act of 2012 and DSWD operational guidelines

---

## Scope and Delimitation

**Scope**

VisioSphere covers the development and deployment of a web and mobile monitoring system for DSWD-accredited elderly care facilities in the National Capital Region, with Golden Acres Home for the Aged as the primary implementation site. The system uses YOLOv11, MediaPipe, and OpenCV to analyze live CCTV footage and detect falls, prolonged inactivity, and agitation risk in real time.

The web dashboard is designed for administrators and nurses. Both can receive real-time alerts and incident reports. Administrators additionally manage resident records, user accounts, and system activity logs. The mobile app supports administrators, nurses, and guardians — administrators and nurses can monitor residents and receive alerts on the go, while guardians receive notifications and daily summaries about their loved ones.

Access to sensitive features such as live video and system controls is restricted based on user role to ensure privacy, safety, and security.

**Delimitations**

The system is limited to DSWD-accredited facilities in the NCR. Detection accuracy depends on the resolution, placement, and coverage of the facility's existing cameras.

Fall and behavior detection uses rule-based pose estimation — the system does not perform facial recognition and does not diagnose any medical condition. Camera coverage is strictly limited to high-risk common areas; private spaces such as bathrooms and bedrooms are excluded.

The Guardian Mobile App is read-only: family members can receive notifications and view updates, but live video access is reserved for administrators and nurses.

The system requires a stable Wi-Fi connection and continuous power supply. Weak or lost connectivity may delay alert delivery, and the system will not function during power outages unless backup power is available — backup power infrastructure is outside the scope of this project.

System evaluation covers Functional Suitability, Performance Efficiency, and Usability only (ISO/IEC 25010). The system does not integrate with external emergency services or third-party healthcare platforms.

---

## Evaluation

The system is evaluated against the ISO/IEC 25010 software quality standard across three dimensions: Functional Suitability, Performance Efficiency, and Usability. User Acceptance Testing was conducted with facility administrators, nurses, and guardians at Golden Acres.

**Performance targets met:**
- Fall event detection and alert delivery: under 2 seconds from incident occurrence
- Emergency log push to dashboard: under 100ms network latency
- Minimum processing rate: 15 frames per second on GPU-equipped hardware

---

*VisioSphere is a capstone project developed by MERGE-IT at National University – CCIT, in partnership with Golden Acres Home for the Aged.*
