# Backend Hosting Setup

This project supports two modes:

- `USE_MOCK_API=true`: run app without backend.
- `USE_MOCK_API=false`: call real hosted backend.

## 1) Before Hosting

Make sure backend has these routes implemented:

- `POST /auth/register/client`
- `POST /auth/login`
- `POST /auth/refresh-token`
- `POST /auth/google/login/client`
- `POST /auth/google/register/client`
- `POST /auth/otp/send`
- `POST /auth/otp/verify`
- `GET /users/me`
- `GET /posts`
- `POST /posts`
- `GET /categories`
- `GET /categories/active`
- `GET /categories/:id/sub-categories`
- `GET /banners` or `GET /banners/active`

## 2) Hosting Configuration

- Use HTTPS in production.
- If backend is behind Nginx/Apache, proxy `/api/*` to your app server.
- Enable CORS for the client origins and headers:
  - `Authorization`
  - `Content-Type`
- Allow request payload size large enough for image upload.
- Keep timezone and server clock correct for token expiry logic.

## 3) App Launch Commands

### Mock mode

```bash
flutter run --dart-define=USE_MOCK_API=true
```

### Hosted backend mode

```bash
flutter run \
  --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=https://your-domain.com/api
```

## 4) Release Validation

- Login/register works.
- Home loads products, categories, and banners.
- Create post works with images.
- OTP endpoints return expected response shape.
- `/users/me` returns profile coordinates when available.
