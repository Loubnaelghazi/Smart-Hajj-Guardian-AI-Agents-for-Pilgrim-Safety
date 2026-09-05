from typing import Any

import httpx

from .config import (
    CONGESTION_AUTH_TOKEN,
    CONGESTION_CALLBACK_URL,
    NOKIA_API_HOST,
    NOKIA_API_KEY,
    NOKIA_BASE_URL,
)


class NokiaAPIError(
    RuntimeError
):

    def __init__(
        self,
        status_code: int,
        detail: Any,
    ):

        self.status_code = (
            status_code
        )

        self.detail = detail

        super().__init__(
            f"Nokia API HTTP "
            f"{status_code}: {detail}"
        )


class NokiaClient:

    def __init__(
        self
    ):

        self.base_url = (
            NOKIA_BASE_URL.rstrip("/")
        )


    @property
    def headers(
        self
    ):

        return {

            "Content-Type":
                "application/json",

            "x-rapidapi-host":
                NOKIA_API_HOST,

            "x-rapidapi-key":
                NOKIA_API_KEY,
        }


    async def _request(
        self,
        method: str,
        path: str,
        json: dict | None = None,
        extra_headers: dict | None = None,
    ):

        if not NOKIA_API_KEY:

            raise NokiaAPIError(
                500,
                "NOKIA_API_KEY is not configured.",
            )


        url = (
            f"{self.base_url}/"
            f"{path.lstrip('/')}"
        )


        headers = dict(
            self.headers
        )


        if extra_headers:

            headers.update(
                extra_headers
            )


        try:

            async with httpx.AsyncClient(
                timeout=30.0
            ) as http:

                response = (
                    await http.request(

                        method=
                            method,

                        url=
                            url,

                        headers=
                            headers,

                        json=
                            json,
                    )
                )


        except httpx.RequestError as exc:

            raise NokiaAPIError(
                502,
                (
                    "Could not reach "
                    f"Nokia API: {exc}"
                ),
            )


        try:

            data = (
                response.json()
                if response.content
                else {}
            )


        except ValueError:

            data = {
                "raw":
                    response.text
            }


        if response.is_error:

            raise NokiaAPIError(
                response.status_code,
                data,
            )


        return data


    # =====================================================
    # LOCATION RETRIEVAL
    #
    # Kept available, but NOT called automatically
    # by Guardian because current app gets 403.
    # =====================================================

    async def retrieve_location(
        self,
        phone_number: str,
        max_age: int = 600,
    ):

        return await self._request(
            "POST",

            (
                "/location-retrieval/"
                "v0/retrieve"
            ),

            {
                "device": {

                    "phoneNumber":
                        phone_number
                },

                "maxAge":
                    max_age,
            },
        )


    # =====================================================
    # REAL LOCATION VERIFICATION
    # =====================================================

    async def verify_location(
        self,
        phone_number: str,
        latitude: float,
        longitude: float,
        radius: int,
        max_age: int = 120,
    ):

        return await self._request(
            "POST",
            "/location-verification/v1/verify",
            {
                "device": {
                    "phoneNumber": phone_number
                },

                "area": {
                    "areaType": "CIRCLE",

                    "center": {
                        "latitude": latitude,
                        "longitude": longitude,
                    },

                    "radius": radius,
                },
            },
        )

    # =====================================================
    # REACHABILITY
    # =====================================================

    async def retrieve_reachability(
        self,
        phone_number: str,
    ):

        return await self._request(
            "POST",

            (
                "/device-status/"
                "device-reachability-status/"
                "v1/retrieve"
            ),

            {
                "device": {

                    "phoneNumber":
                        phone_number
                }
            },
        )


    # =====================================================
    # CONSENT
    # =====================================================

    async def retrieve_consent_status(
        self,
        phone_number: str,
        scopes: list[str],
        purpose: str,
        request_capture_url: bool,
    ):

        return await self._request(
            "POST",

            (
                "/passthrough/camara/v1/"
                "consent-info/"
                "consent-info/v0.1/"
                "retrieve"
            ),

            {
                "phoneNumber":
                    phone_number,

                "scopes":
                    scopes,

                "purpose":
                    purpose,

                "requestCaptureUrl":
                    request_capture_url,
            },
        )


    # =====================================================
    # NUMBER VERIFICATION
    # =====================================================

    async def verify_phone_number(
        self,
        phone_number: str,
        bearer_token: str | None = None,
    ):

        headers = {}


        if bearer_token:

            headers[
                "Authorization"
            ] = (
                f"Bearer "
                f"{bearer_token}"
            )


        return await self._request(
            "POST",

            (
                "/passthrough/camara/v1/"
                "number-verification/"
                "number-verification/v2/"
                "verify"
            ),

            {
                "phoneNumber":
                    phone_number
            },

            extra_headers=
                headers,
        )


    # =====================================================
    # QOD
    # =====================================================

    async def create_qod_session(
        self,
        phone_number: str,
        public_address: str,
        private_address: str,
        public_port: int,
        application_server_ipv4: str,
        qos_profile: str,
        duration: int,
    ):

        return await self._request(
            "POST",

            "/quality-on-demand/v1/sessions",

            {
                "device": {

                    "phoneNumber":
                        phone_number,

                    "ipv4Address": {

                        "publicAddress":
                            public_address,

                        "privateAddress":
                            private_address,

                        "publicPort":
                            public_port,
                    },
                },

                "applicationServer": {

                    "ipv4Address":
                        application_server_ipv4,
                },

                "qosProfile":
                    qos_profile,

                "duration":
                    duration,
            },
        )


    async def get_qod_session(
        self,
        session_id: str,
    ):

        return await self._request(
            "GET",

            (
                "/quality-on-demand/v1/"
                f"sessions/{session_id}"
            ),
        )


    async def delete_qod_session(
        self,
        session_id: str,
    ):

        return await self._request(
            "DELETE",

            (
                "/quality-on-demand/v1/"
                f"sessions/{session_id}"
            ),

            {},
        )


    # =====================================================
    # CONGESTION
    # =====================================================

    def congestion_payload(
        self,
        phone_number: str,
        expire_time: str,
    ):

        return {

            "device": {

                "phoneNumber":
                    phone_number
            },

            "webhook": {

                "notificationUrl":
                    CONGESTION_CALLBACK_URL,

                "notificationAuthToken":
                    CONGESTION_AUTH_TOKEN,
            },

            "subscriptionExpireTime":
                expire_time,
        }


    async def create_congestion_subscription(
        self,
        phone_number: str,
        expire_time: str,
    ):

        return await self._request(
            "POST",

            (
                "/congestion-insights/"
                "v0/subscriptions"
            ),

            self.congestion_payload(
                phone_number,
                expire_time,
            ),
        )


    async def query_congestion(
        self,
        phone_number: str,
        expire_time: str = (
            "2045-04-12T14:09:33+05:00"
        ),
    ):

        return await self._request(
            "POST",

            (
                "/congestion-insights/"
                "v0/query"
            ),

            self.congestion_payload(
                phone_number,
                expire_time,
            ),
        )