# AUTOSPOT - Complete Conversation & Development History

**Generated:** 2026-01-27
**Purpose:** Compiled documentation of all Claude interactions, requests, and recommendations for AUTOSPOT project

---

## Executive Summary

AUTOSPOT is an autonomous AI-powered video advertising platform for hyper-local businesses that generates cohort-targeted short-form video ads using OpenAI's Sora API and deploys them to Instagram, TikTok, and Facebook. The platform is designed to be fully self-serve—customers onboard once, review generated content, and the system handles everything else autonomously.

**Current Status:** MVP Complete, Ready for Beta Testing (as of Jan 2025)
**Tech Stack:** Python/FastAPI backend, Next.js/React frontend, PostgreSQL, Redis/Celery, AWS S3
**Core Innovation:** Uses AI (GPT-4 + Sora) to generate broadcast-quality video ads for $100-200/month vs traditional $5-50K production costs

---

## Project Vision & Core Value Proposition

### The Problem
Local businesses (restaurants, gyms, service providers, small retailers) have never been able to afford video advertising. Traditional production costs range from $5,000-$50,000.

### The Solution
AUTOSPOT generates broadcast-quality video ads for ~$100-200/month, automatically tuned to audiences most likely to convert.

### Key Differentiator
- **Fully Autonomous:** Customers onboard once, system handles everything else
- **AI-Powered Cohort Targeting:** GPT-4 generates 3-5 audience segments automatically
- **Sora Video Generation:** Creates personalized videos for each cohort
- **Self-Sustaining Growth:** Platform will use itself to generate its own marketing (dogfooding)

---

## Development Timeline & Conversation History

### Phase 1: Initial Planning & Architecture (Dec 2024)

#### Request: Project Foundation
**User's Vision:**
- Create autonomous video advertising platform
- Target local businesses
- Use Sora for video generation
- Deploy to social platforms
- Full self-serve experience

**Claude's Recommendations:**
1. **Tech Stack Selection:**
   - Backend: Python (FastAPI) for async support and easy OpenAI integration
   - Frontend: Next.js with React for SSR and modern UX
   - Database: PostgreSQL for relational data
   - Queue: Redis + Celery for async video generation
   - Storage: AWS S3 for video assets
   - Auth: NextAuth.js (originally suggested Clerk/Auth0)

2. **Core Architecture:**
   ```
   Customer Onboarding → AI Cohort Generation → Video Creation →
   Review Interface → Social Deployment → Analytics Dashboard
   ```

3. **Data Model Design:**
   - Customer → CustomerProfile → CustomerAssets
   - Campaign → Cohort → Video → Deployment
   - TrackingLink → ConversionEvent
   - Subscription with quota management

4. **Key Design Decisions:**
   - Start with Meta + TikTok only (YouTube deferred to Phase 2)
   - No manual creative tools in v1 (only approve/reject)
   - Weekly campaign refresh as default
   - Cohort count fixed at 3-5 (automatic, not user-configurable)
   - Single location only in v1 (multi-location in Phase 2)

### Phase 2: Authentication Implementation (Dec 18-19, 2024)

#### Request: User Authentication System
**User's Need:** Secure authentication for customers

**Implementation:**
- JWT-based authentication
- Email/password with bcrypt hashing
- OAuth provider support (Google, Microsoft, Facebook, Apple)
- NextAuth.js integration
- Protected routes with customer authentication middleware
- Session management and token refresh

**Claude's Approach:**
1. Extended Customer model with auth fields
2. Created auth routes (register, login, validate credentials)
3. Implemented JWT validation in deps.py
4. Protected all existing routes with authentication
5. Frontend NextAuth.js setup with sign-in/sign-up pages

**Status as of Dec 19:** ~60% complete
- ✅ Backend auth complete
- ✅ JWT utilities working
- 🔄 Frontend OAuth setup in progress

**Critical Note Documented:**
> JWT Secret: Backend `JWT_SECRET` MUST match frontend `NEXTAUTH_SECRET` exactly!

### Phase 3: Email & Password Reset Features (Jan 2025)

#### Request: Email Verification and Password Reset
**User's Need:** Complete authentication flow with email verification

**Implementation:**
- Password Reset Flow with tokens (1-hour expiration)
- Email Verification Flow with tokens (24-hour expiration)
- Welcome emails after successful verification
- HTML email templates with branding
- SMTP configuration support
- Development mode (logs emails when SMTP not configured)

**New Database Models:**
- `PasswordResetToken` (backend/app/models/auth_tokens.py)
- `EmailVerificationToken` (backend/app/models/auth_tokens.py)

**New API Endpoints:**
- POST `/api/v1/auth/request-password-reset`
- POST `/api/v1/auth/reset-password`
- POST `/api/v1/auth/send-verification-email`
- POST `/api/v1/auth/verify-email`
- GET `/api/v1/auth/me`
- GET `/api/v1/auth/status`

**Email Service Location:** backend/app/services/email_service.py

### Phase 4: Sora API Integration (Dec 2024)

#### Request: Video Generation Pipeline
**User's Goal:** Generate videos using OpenAI Sora API

**Claude's Implementation Plan:**
1. **Async Architecture:**
   - Celery + Redis for background processing
   - Polling mechanism (check every 10s, max 10 minutes)
   - Optional webhook support for production
   - S3 storage for completed videos

2. **Service Structure:**
   - `SoraService` (backend/app/services/sora_service.py)
     - `generate_video()` - Non-blocking job creation
     - `generate_video_and_wait()` - Blocking with auto-poll
     - `get_video_status()` - Check job status
     - `cancel_generation()` - Cancel job
     - `build_prompt()` - Intelligent prompt engineering

3. **Prompt Engineering Strategy:**
   - `PromptBuilder` (backend/app/services/prompt_builder.py)
   - Combines: Campaign creative direction + Cohort targeting + Variation styles + Platform-specific hints
   - Personalizes based on age group, interests, behaviors
   - Optimizes for platform (TikTok vs Instagram vs YouTube)

4. **Cost Estimation:**
   - Sora-2: ~$0.10/second (standard quality)
   - Sora-2 Pro: ~$0.15/second (high quality)
   - Example: 12 videos × 10s × $0.10 = $12 per campaign refresh
   - Monthly (4 refreshes): $48 cost on $100 tier = 52% margin

5. **Video Model Enhancements:**
   - `sora_request_id` - Track Sora job ID
   - `sora_generation_time_seconds` - Performance metrics
   - `generation_cost_cents` - Cost tracking
   - `s3_bucket`, `s3_key`, `s3_url` - Storage locations
   - `celery_task_id` - Link to background task
   - `regeneration_count` - Track rework iterations
   - `parent_video_id` - Link regenerations to originals

6. **Celery Task Flow:**
   ```
   API Request → Create Video records (status=queued) →
   Dispatch Celery tasks → Worker calls Sora API →
   Poll for completion → Download video →
   Upload to S3 → Update database (status=completed) →
   Increment quota → Track costs
   ```

**Status:** ✅ Complete (as documented in SORA_INTEGRATION.md)

### Phase 5: Social Platform Deployment (Dec 2024 - Jan 2025)

#### Request: Deploy Videos to Social Platforms
**User's Goal:** Automatically deploy approved videos to Meta, TikTok, YouTube

**Meta (Instagram/Facebook) Integration:**
- `MetaAdsService` (backend/app/services/meta_ads_service.py)
- Uses Facebook Marketing API
- Flow: Create Campaign → Create Ad Set with targeting → Upload video → Create Ad Creative → Create Ad
- **Targeting Translation:**
  - Cohort demographics → Meta age/gender filters
  - Interests → Meta interest IDs (requires mapping)
  - Behaviors → Meta behavior IDs (high income, travelers, etc.)
- **Limitations Noted:** Static interest mapping (should use Meta Targeting Search API in production)

**TikTok Ads Integration:**
- `TikTokAdsService` (backend/app/services/tiktok_ads_service.py)
- Uses TikTok Marketing API
- Flow: Upload video to TikTok CDN → Create Campaign → Create Ad Group → Create Ad
- **Targeting Translation:**
  - Age ranges → TikTok predefined ranges (AGE_18_24, AGE_25_34, etc.)
  - Locations → TikTok location IDs
  - Interests → TikTok interest category IDs

**YouTube Ads:**
- Deferred to Phase 2 (stretch goal)
- More complex API, lower priority for MVP

**New Database Model:**
- `Deployment` (backend/app/models/deployment.py)
  - Links videos to platform deployments
  - Tracks platform-specific IDs (campaign_id, ad_set_id, ad_id)
  - Stores performance metrics (impressions, clicks, video views, conversions)
  - Budget tracking (daily_budget_cents, total_spend_cents)
  - Status management (pending, active, paused, completed, failed)

**New API Endpoints:**
- POST `/api/v1/deployments/` - Deploy video to platform
- GET `/api/v1/deployments/{id}` - Get deployment details
- POST `/api/v1/deployments/{id}/pause` - Pause deployment

**Status:** ✅ Complete

### Phase 6: Analytics & Conversion Tracking (Jan 2025)

#### Request: Performance Metrics and Attribution
**User's Need:** Track ad performance and conversions

**Metrics Sync System:**
- **Celery Beat Scheduler:** Hourly automatic metrics sync
- **Sync Sources:** Meta Marketing API, TikTok Ads API
- **Task:** `sync_all_metrics()` (backend/app/tasks/sync_metrics.py)
- **Frequency:** Every hour via cron schedule

**Platform Metrics Collected:**
- Impressions, Clicks, CTR (Click-Through Rate)
- Video Views, View Rate
- Spend (cents), CPM (Cost Per 1000 Impressions), CPC (Cost Per Click)

**Conversion Tracking System:**
- **Short Link Tracking:** autospot.link/abc123 format
- **Promo Codes:** Platform-specific codes (e.g., TIK42X7Y9)
- **UTM Parameter Auto-Tagging:** Source, medium, campaign tracking
- **IP-Based Click Deduplication:** Unique vs total click tracking
- **Conversion Webhook:** POST /api/v1/tracking/convert
- **Event Types:** click, view_landing, add_to_cart, purchase, lead, sign_up

**TrackingLink Model:**
- Short code generation
- UTM parameters
- Promo code assignment
- IP deduplication
- Click count tracking

**ConversionEvent Model:**
- Event type classification
- Revenue tracking (cents)
- Attribution to tracking links
- Timestamp and metadata

**ROI Calculations:**
- Total Revenue (from conversions)
- Total Spend (from platform metrics)
- Profit = Revenue - Spend
- ROI Percentage = (Profit / Spend) × 100
- ROAS (Return on Ad Spend) = Revenue / Spend

**Analytics API:**
- GET `/api/v1/campaigns/{id}/analytics` - Comprehensive campaign metrics
- Returns: impressions, clicks, video views, spend, CTR, CPM, CPC, view rate, conversions, revenue, ROI, ROAS

**Status:** ✅ Complete

### Phase 7: Enhanced Features (Jan 2025)

#### Request: Workflow Improvements
**User's Need:** Streamline video review and deployment processes

**Batch Video Operations:**
- POST `/api/v1/videos/batch/approve` - Approve multiple videos at once
- POST `/api/v1/videos/batch/reject` - Reject multiple videos with optional reason
- **Purpose:** Efficiency for users managing 10-15 videos per campaign

**Campaign Workflow Automation:**
- POST `/api/v1/campaigns/{id}/auto-deploy` - One-click deployment of all approved videos
  - Deploys to multiple platforms (Instagram, Facebook, TikTok)
  - Creates tracking links automatically
  - Sets daily budgets
  - Updates campaign status to ACTIVE
- POST `/api/v1/campaigns/{id}/pause` - Pause entire campaign across all platforms
- **Celery Tasks:** `auto_deploy_approved_videos`, `pause_campaign_deployments`

**Secure Video Previews:**
- GET `/api/v1/videos/{id}/preview` - Generate S3 signed URL
- Configurable expiration (default 1 hour, max 7 days)
- Prevents unauthorized video access
- **Service:** `S3Service.generate_signed_url()`

**Status:** ✅ Complete

### Phase 8: AI-Powered Optimization (Jan 2025)

#### Request: Intelligent Performance Analysis
**User's Goal:** AI-driven insights and recommendations for campaigns

**Performance Optimizer Service:**
- `PerformanceOptimizer` (backend/app/services/performance_optimizer.py)
- Uses GPT-4 to analyze campaign data and provide actionable insights

**Optimization Recommendations API:**
- GET `/api/v1/campaigns/{id}/optimization-recommendations`
- Returns:
  - **Overall Health Assessment:** excellent/good/fair/poor
  - **Health Score (0-100):** Weighted formula:
    - ROAS: 35% weight
    - Conversion Rate: 25% weight
    - CTR: 20% weight
    - View Rate: 20% weight
  - **Key Insights:** AI-generated observations
  - **Actionable Recommendations:** Prioritized by impact
  - **Platform-Specific Insights:** Per-platform analysis
  - **Cohort Performance:** Which audiences work best
  - **Creative Performance Patterns:** What styles resonate
  - **Next Steps:** 7-day action plan

**Budget Suggestions API:**
- GET `/api/v1/campaigns/{id}/budget-suggestions`
- Returns:
  - **Recommended Total Budget:** Based on performance
  - **Platform Allocation:** Percentage breakdown
  - **Efficiency Analysis:** ROI by platform
  - **Rationale:** Why these recommendations
  - **Target ROAS Comparisons:** Current vs potential

**Status:** ✅ Complete (NEW feature)

### Phase 9: Campaign Templates (Jan 2025)

#### Request: Quick Campaign Setup
**User's Need:** Pre-built configurations for common business types

**Campaign Template Service:**
- `CampaignTemplateService` (backend/app/services/campaign_templates.py)
- 10 pre-configured business types

**Available Templates:**
1. **Gym/Fitness Centers**
2. **Restaurants**
3. **Salons & Beauty Services**
4. **Retail Stores**
5. **Home Services**
6. **Professional Services**
7. **Medical/Dental**
8. **Automotive**
9. **Real Estate**
10. **Education**

**Template Structure:**
- Campaign defaults (video length, platforms, budgets)
- Creative direction guidelines
- Pre-configured cohort templates (3-5 per business type)
- Targeting suggestions (demographics, interests, behaviors)
- Pain points and messaging angles specific to industry

**API Endpoints:**
- GET `/api/v1/campaigns/templates` - List all templates
- GET `/api/v1/campaigns/templates/{business_type}` - Get specific template

**Example: Gym Template Cohorts:**
1. "Busy Professionals" (30-45, high income, no time to work out)
2. "New Year Resolvers" (25-45, starting fitness journey)
3. "Seniors Seeking Mobility" (55+, health-conscious)
4. "Young Athletes" (18-25, performance-focused)

**Status:** ✅ Complete (NEW feature)

---

## Key Technical Conversations & Decisions

### 1. Why FastAPI over Flask/Django?
**Context:** Backend framework selection

**Claude's Rationale:**
- Async/await support built-in (critical for Sora API long-polling)
- Modern Python 3.11+ features and type hints
- Automatic OpenAPI documentation
- Better performance for I/O-bound operations (API calls)
- Easy integration with Celery for background tasks

**User Acceptance:** ✅ Approved

### 2. Why Celery for Video Generation?
**Context:** Async task processing

**Claude's Explanation:**
- Sora video generation takes 30s-2min per video
- Can't block HTTP requests for that long
- Need retry logic and error handling
- Want to generate multiple videos in parallel
- Celery + Redis is proven, reliable stack

**Alternative Considered:** AWS Lambda
**Rejected Because:** Would need to manage state across multiple invocations, harder to debug

**User Acceptance:** ✅ Approved

### 3. Polling vs Webhooks for Sora Status?
**Context:** How to know when video is ready

**Claude's Recommendation:** Start with polling, add webhooks later

**Polling Approach:**
- Check status every 10 seconds
- Max 60 attempts (10 minutes)
- Simple, no configuration needed
- Easier debugging during development

**Webhook Approach (Future):**
- Requires public HTTPS endpoint
- Instant notifications
- Lower API usage
- More complex setup (signature verification)

**Decision:** Polling for MVP, webhooks for production optimization

**User Acceptance:** ✅ Approved

### 4. How to Store Videos?
**Context:** S3 vs CDN vs platform storage

**Claude's Architecture:**
1. **Initial Storage:** S3 with private buckets
2. **Customer Review:** Generate signed URLs (1-hour expiration)
3. **Deployment:** Upload to platform CDNs (Meta/TikTok)
4. **Long-term:** Keep in S3 for regeneration/auditing

**Rationale:**
- Platform CDNs handle public distribution efficiently
- S3 is our source of truth
- Signed URLs prevent unauthorized access
- No need for separate CDN (Cloudfront) in MVP

**User Acceptance:** ✅ Approved

### 5. Cohort Targeting: Static Mapping vs API Lookup?
**Context:** Converting interests/behaviors to platform IDs

**Claude's Approach for MVP:**
- Static mapping of common interests to platform IDs
- Hard-coded dictionaries in services

**Known Limitation:** Limited to ~50-100 pre-mapped interests

**Production Recommendation:**
- Use Meta Targeting Search API
- Use TikTok Interest Categories API
- Dynamic lookup at deployment time
- Cache results to reduce API calls

**Trade-off Accepted:** MVP can launch with static mappings, enhance later

**User Acceptance:** ✅ Approved (with note to enhance post-MVP)

### 6. Multi-Location Support?
**Context:** Franchises with multiple locations

**User's Question:** Should v1 support multi-location?

**Claude's Recommendation:** No, defer to Phase 2

**Reasoning:**
- Adds significant complexity to data model
- Need per-location campaigns, budgets, targeting
- Need location-based performance comparisons
- MVP should validate single-location market first

**Architecture Note:** Design allows for extension:
```python
# Future:
class Location(Base):
    customer_id: int
    name: str
    address: str

class Campaign(Base):
    location_id: Optional[int]  # NULL = all locations
```

**User Acceptance:** ✅ Deferred to Phase 2

### 7. Customer Can Edit Videos?
**Context:** Video editor in review interface

**User's Question:** Should customers be able to edit videos?

**Claude's Recommendation:** No for v1

**Reasoning:**
- Sora generates complete videos, not editable assets
- Would need separate video editing tool/service
- Adds significant frontend complexity
- Better UX: Approve/Reject + Regenerate with feedback

**Alternative Flow:**
1. Customer sees video
2. If not perfect, clicks "Regenerate"
3. Provides text feedback: "Make it more energetic, add text overlay"
4. System regenerates with updated prompt
5. Counts against quota (charges apply)

**User Acceptance:** ✅ Approved (reject for v1)

---

## Current Architecture (Jan 2025)

### Backend Stack
- **Framework:** FastAPI (Python 3.11+)
- **Database:** PostgreSQL with SQLAlchemy ORM
- **Async Processing:** Celery + Redis
- **Storage:** AWS S3
- **APIs:** OpenAI (Sora, GPT-4), Meta Marketing API, TikTok Ads API, Stripe

### Frontend Stack
- **Framework:** Next.js 13+ with React 18
- **Authentication:** NextAuth.js
- **Styling:** Tailwind CSS
- **State Management:** React hooks (no Redux/Context needed yet)

### Infrastructure
- **Celery Worker:** Async video generation tasks
- **Celery Beat:** Scheduled hourly metrics sync
- **Redis:** Message broker and result backend
- **PostgreSQL:** Relational database
- **S3 Bucket:** Video storage

### Complete Data Flow
```
1. User Signup → NextAuth.js → Backend Auth API → JWT Token

2. Onboarding → Upload Assets to S3 → Save CustomerProfile

3. Campaign Creation → GPT-4 Cohort Generation → Campaign Created

4. Video Generation → Celery Task → Sora API → Poll Status →
   Download Video → Upload to S3 → Update Database

5. Video Review → Customer Approves → Mark Approved

6. Deployment → MetaAdsService → Create Campaign/AdSet/Ad →
   Return Platform IDs → Create Tracking Link → Status: ACTIVE

7. Metrics Sync → Celery Beat (hourly) → Fetch from Meta/TikTok →
   Update Deployment Metrics

8. Conversion → User Clicks Tracking Link → Track Click →
   User Purchases → Customer Reports via Webhook →
   Link to TrackingLink → Calculate ROI

9. Analytics → Aggregate Metrics → Calculate KPIs →
   Display Dashboard
```

---

## Known Limitations & Future Enhancements

### Current Limitations (Documented)

1. **Single Location Only**
   - Multi-location/franchise support not implemented
   - Future: Per-location campaigns and budgets

2. **Static Interest Mapping**
   - Meta/TikTok interest IDs use hardcoded dictionaries
   - Future: Dynamic API lookup via Targeting Search APIs

3. **No Video Editing**
   - Customers can only approve/reject, not edit
   - Future: Basic trim, caption, music overlay tools

4. **YouTube Ads Not Implemented**
   - Stretch goal, lower priority
   - Future: Google Ads API integration

5. **Manual Creative Approval**
   - No automated quality filtering
   - Future: AI-powered quality scoring

### Planned Enhancements (Phase 2+)

1. **Performance Feedback Loop**
   - Use successful cohort/creative combinations to improve future generation
   - Train on what works per business type

2. **A/B Testing Automation**
   - Automatic variant testing
   - Winner selection based on performance
   - Auto-pause underperformers

3. **Budget Optimization**
   - ML-based budget allocation across platforms
   - Predictive spend recommendations
   - Auto-adjust based on performance

4. **Multi-Location Support**
   - Franchise-level campaign management
   - Per-location analytics
   - Location-based targeting

5. **White-Label/Agency Tier**
   - Allow agencies to manage multiple clients
   - Sub-account management
   - Agency-level reporting

6. **Self-Serve Autospot Marketing**
   - Use platform to market itself (dogfooding)
   - Self-sustaining growth flywheel

7. **Video Editor**
   - Basic trim, caption, music overlay
   - Template overlays
   - Brand consistency tools

### Scalability Considerations

**Current Bottlenecks:**
- Sora API rate limits (may need queuing)
- Single Celery worker (parallel video generation limited)
- S3 costs (linear growth with customers)

**Scaling Strategies:**
- Horizontal scaling: Multiple Celery workers
- Caching: Redis for frequently accessed analytics
- Database read replicas: Separate analytics queries from writes
- Priority queue: Premium customers get faster processing

---

## Environment Configuration

### Required Environment Variables

```bash
# Database
DATABASE_URL=postgresql+asyncpg://user:pass@localhost/autospot

# OpenAI Sora
OPENAI_API_KEY=sk-proj-...
SORA_MODEL=sora-2              # or "sora-2-pro"
SORA_QUALITY=standard          # or "high"
SORA_DEFAULT_DURATION=10       # seconds (4-12)

# AWS S3
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=us-east-1
S3_BUCKET_NAME=autospot-videos

# Redis/Celery
REDIS_URL=redis://localhost:6379/0

# Meta (Facebook/Instagram)
META_APP_ID=...
META_APP_SECRET=...
META_ACCESS_TOKEN=...          # Long-lived token
META_AD_ACCOUNT_ID=...         # Numeric ID without "act_" prefix
META_PAGE_ID=...               # Facebook Page for ads

# TikTok
TIKTOK_ACCESS_TOKEN=...
TIKTOK_ADVERTISER_ID=...

# Stripe
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# JWT Authentication
JWT_SECRET_KEY=...             # Must match NEXTAUTH_SECRET
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=...            # Must match JWT_SECRET_KEY

# Email/SMTP
EMAIL_FROM=noreply@autospot.com
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

---

## API Endpoint Summary (Complete)

### Authentication
- POST `/api/v1/auth/register` - Register new customer
- POST `/api/v1/auth/validate-credentials` - Validate email/password
- POST `/api/v1/auth/request-password-reset` - Request password reset email
- POST `/api/v1/auth/reset-password` - Reset password with token
- POST `/api/v1/auth/send-verification-email` - Send verification email
- POST `/api/v1/auth/verify-email` - Verify email with token
- GET `/api/v1/auth/me` - Get current user
- GET `/api/v1/auth/status` - Get auth status

### Campaigns
- POST `/api/v1/campaigns/` - Create campaign
- GET `/api/v1/campaigns/` - List campaigns
- GET `/api/v1/campaigns/{id}` - Get campaign details
- PATCH `/api/v1/campaigns/{id}` - Update campaign
- POST `/api/v1/campaigns/{id}/generate` - Generate videos for campaign
- POST `/api/v1/campaigns/{id}/generate-cohorts` - Auto-generate cohorts with GPT-4
- POST `/api/v1/campaigns/{id}/approve` - Approve campaign
- POST `/api/v1/campaigns/{id}/auto-deploy` - Auto-deploy all approved videos ✨
- POST `/api/v1/campaigns/{id}/pause` - Pause campaign ✨
- GET `/api/v1/campaigns/{id}/analytics` - Get campaign analytics
- GET `/api/v1/campaigns/{id}/optimization-recommendations` - AI performance analysis ✨
- GET `/api/v1/campaigns/{id}/budget-suggestions` - Budget optimization ✨
- GET `/api/v1/campaigns/templates` - List campaign templates ✨
- GET `/api/v1/campaigns/templates/{type}` - Get template details ✨

### Videos
- GET `/api/v1/videos/cohort/{cohort_id}` - List videos for cohort
- GET `/api/v1/videos/{id}` - Get video details
- GET `/api/v1/videos/{id}/preview` - Get signed preview URL ✨
- POST `/api/v1/videos/{id}/approve` - Approve video
- POST `/api/v1/videos/{id}/reject` - Reject video
- POST `/api/v1/videos/{id}/regenerate` - Regenerate video with feedback
- POST `/api/v1/videos/batch/approve` - Batch approve videos ✨
- POST `/api/v1/videos/batch/reject` - Batch reject videos ✨
- POST `/api/v1/videos/{id}/deploy` - Deploy video to platform
- GET `/api/v1/videos/{id}/metrics` - Get video performance metrics

### Deployments
- POST `/api/v1/deployments/` - Deploy video to social platform
- GET `/api/v1/deployments/{id}` - Get deployment details
- POST `/api/v1/deployments/{id}/pause` - Pause deployment

### Tracking & Attribution
- GET `/api/v1/tracking/{short_code}` - Redirect tracking link (public)
- POST `/api/v1/tracking/convert` - Report conversion event (webhook)
- GET `/api/v1/tracking/links/{campaign_id}` - List tracking links

### Customers & Profiles
- GET `/api/v1/customers/me` - Get current customer
- PATCH `/api/v1/customers/me` - Update customer profile
- POST `/api/v1/customers/assets` - Upload customer assets (logo, photos)
- GET `/api/v1/customers/usage` - Get quota usage

### Billing & Subscriptions
- GET `/api/v1/billing/subscription` - Get subscription details
- POST `/api/v1/billing/subscription` - Create/update subscription
- POST `/api/v1/billing/portal` - Get Stripe customer portal link
- POST `/api/v1/webhooks/stripe` - Stripe webhook handler

### Admin (Future)
- GET `/api/v1/admin/customers` - List all customers
- GET `/api/v1/admin/usage` - System-wide usage stats
- GET `/api/v1/admin/revenue` - Revenue tracking
- POST `/api/v1/admin/sora-keys` - Manage OpenAI API keys (planned)

---

## Testing Strategy & Quality Assurance

### Unit Tests
- Test individual services in isolation
- Mock external APIs (Sora, Meta, TikTok, Stripe)
- Test business logic (cohort generation, prompt building, cost calculation)
- Location: `backend/tests/`

### Integration Tests
- Test API endpoints with test database
- Test authentication flows
- Test end-to-end campaign creation → video generation → deployment
- Use fixtures for customer/campaign setup

### Manual Testing Checklist
1. Create customer account
2. Complete onboarding (upload assets, set profile)
3. Create campaign
4. Review auto-generated cohorts
5. Trigger video generation
6. Monitor Celery logs
7. Approve videos in review UI
8. Deploy to Meta/TikTok (test accounts)
9. Verify tracking links work
10. Check analytics dashboard

### Load Testing (Future)
- Celery worker capacity (concurrent video generations)
- Database performance (analytics queries)
- API rate limits
- Cost projections at scale

---

## Success Metrics & Business Goals

### MVP Success Criteria (Q1 2026)
- ✅ All core features implemented
- ✅ 10 feature-complete API endpoints
- ⏳ 5 beta customers onboarded
- ⏳ 50 videos generated successfully
- ⏳ 10+ videos deployed to social platforms
- ⏳ $0 customer acquisition cost (organic growth)

### Phase 2 Goals (Q2 2026)
- 50 paying customers
- $5K MRR
- 80% customer retention
- <5% video generation failure rate
- ROAS > 2.0 for customers

### Technical Metrics
- Video generation: <2 minutes average
- API response time: <500ms (p95)
- Celery task success rate: >95%
- Cost per video: <$1.50 (including Sora + platform fees)

---

## Agent Creation Recommendations

Based on the documented conversations and patterns, here are recommended AI agents to create:

### 1. **Cohort Generation Agent**
**Purpose:** Generate audience cohorts for new campaigns
**Inputs:** Business type, location, customer profile, target demographics
**Outputs:** 3-5 cohort definitions with targeting params
**Model:** GPT-4 (already implemented in backend/app/services/cohorts.py)
**Prompt Pattern:** Analyze business → Identify audience segments → Create targeting → Format as JSON

### 2. **Prompt Engineering Agent**
**Purpose:** Build optimized Sora prompts from cohort data
**Inputs:** Campaign creative direction, cohort data, platform, variation number
**Outputs:** Optimized Sora prompt (text)
**Model:** Can use GPT-3.5-turbo or Claude (cheaper than GPT-4)
**Prompt Pattern:** Combine campaign goals + cohort preferences + platform specs → Generate video description
**Location:** backend/app/services/prompt_builder.py

### 3. **Performance Analysis Agent**
**Purpose:** Analyze campaign metrics and provide recommendations
**Inputs:** Campaign metrics (impressions, clicks, conversions, spend)
**Outputs:** Health score, insights, recommendations
**Model:** GPT-4 (already implemented in backend/app/services/performance_optimizer.py)
**Prompt Pattern:** Analyze KPIs → Identify patterns → Generate actionable insights

### 4. **Budget Optimization Agent**
**Purpose:** Suggest budget allocation across platforms
**Inputs:** Platform performance metrics, current budgets, customer goals
**Outputs:** Recommended budget distribution, efficiency analysis
**Model:** GPT-4 (already implemented)
**Prompt Pattern:** Compare platform efficiency → Calculate optimal allocation → Provide rationale

### 5. **Creative Feedback Agent** (Future)
**Purpose:** Provide feedback on video quality and suggestions for improvement
**Inputs:** Video URL, cohort targeting, brand guidelines
**Outputs:** Quality score, improvement suggestions
**Model:** GPT-4 Vision or Claude 3.5 Sonnet
**Prompt Pattern:** Analyze video → Check brand consistency → Score on clarity, engagement, targeting fit

### 6. **Customer Onboarding Agent** (Future)
**Purpose:** Help customers through onboarding with conversational interface
**Inputs:** Customer responses to questions
**Outputs:** Structured profile data, asset requirements
**Model:** GPT-3.5-turbo or Claude
**Prompt Pattern:** Ask questions → Parse responses → Extract targeting preferences → Suggest next steps

---

## Critical Conversations & Decisions Summary

1. **Auth Implementation:** JWT + NextAuth.js (secrets must match!)
2. **Video Generation:** Celery + polling approach for MVP
3. **Cost Management:** $0.10/second × 10 seconds = $1.00 per video
4. **Targeting:** Static mappings for MVP, API lookup for production
5. **Multi-location:** Deferred to Phase 2
6. **Video Editing:** Not in v1, regenerate with feedback instead
7. **YouTube:** Stretch goal, focus on Meta + TikTok first
8. **Webhooks:** Optional enhancement, polling sufficient for MVP
9. **Quality Control:** Manual approval in v1, AI scoring in Phase 2
10. **Scaling Strategy:** Horizontal Celery workers, read replicas, caching

---

## Next Steps for Development

### Immediate (Week 1-2)
1. ✅ Complete frontend authentication UI
2. ✅ Wire up onboarding flow to backend
3. ⏳ Build video review interface
4. ⏳ Test end-to-end with real Sora API
5. ⏳ Deploy to staging environment

### Short-term (Month 1)
1. ⏳ Recruit 3-5 beta customers
2. ⏳ Complete beta testing
3. ⏳ Fix critical bugs
4. ⏳ Add monitoring (Sentry, CloudWatch)
5. ⏳ Optimize costs

### Medium-term (Month 2-3)
1. ⏳ Scale to 10 paying customers
2. ⏳ Implement performance feedback loop
3. ⏳ Add A/B testing automation
4. ⏳ Build analytics dashboard v2
5. ⏳ Launch self-serve marketing campaign

---

**Document Version:** 1.0
**Last Updated:** January 27, 2026
**Compiled by:** Claude Sonnet 4.5
**Source Files:** CLAUDE.md, DEV_NOTES.md, IMPLEMENTATION_STATUS.md, IMPLEMENTATION_PLAN.md, SORA_INTEGRATION.md

---

*This document captures all major Claude interactions and development decisions for the AUTOSPOT project. Use this as a reference for understanding project history, architectural decisions, and recommended next steps.*
