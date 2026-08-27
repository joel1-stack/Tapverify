import requests
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

class AfricasTalkingSMSService:
    BASE_URL = "https://api.africastalking.com/version1/messaging"

    def __init__(self):
        self.username = settings.AFRICASTALKING_USERNAME
        self.api_key = settings.AFRICASTALKING_API_KEY
        self.sender_id = getattr(settings, 'AFRICASTALKING_SENDER_ID', 'TAPVERIFY')

    def _headers(self):
        return {
            'apiKey': self.api_key,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json'
        }

    def send_sms(self, to, message, sender_id=None):
        if not self.username or not self.api_key:
            logger.error("Africa's Talking credentials not configured")
            return False, None, "Credentials not configured"

        payload = {
            'username': self.username,
            'to': to,
            'message': message,
            'from': sender_id or self.sender_id,
        }

        try:
            resp = requests.post(
                f"{self.BASE_URL}",
                data=payload,
                headers=self._headers(),
                timeout=30
            )
            data = resp.json()

            if data.get('SMSMessageData', {}).get('Recipients', []):
                recipient = data['SMSMessageData']['Recipients'][0]
                status = recipient.get('status')
                message_id = recipient.get('messageId')

                if status == 'Success':
                    return True, message_id, None
                else:
                    return False, message_id, f"Status: {status}"
            else:
                return False, None, "No recipients in response"

        except Exception as e:
            logger.exception("SMS send failed")
            return False, None, str(e)

    def send_bulk(self, recipients, message):
        results = []
        for r in recipients:
            personalized = message.replace("{name}", r.get('name', ''))
            success, msg_id, error = self.send_sms(r['phone'], personalized)
            results.append((r['phone'], success, msg_id, error))
        return results


def build_receipt_sms(event):
    ws = event.workspace
    member = event.member

    msg = (
        f"TapVerify — Payment Confirmed\n\n"
        f"Hello {member.name},\n"
        f"Ksh {event.amount:,.0f} received by {ws.name}.\n\n"
        f"Collected by: {event.verifier.name if event.verifier else 'System'}\n"
        f"Date: {event.created_at.strftime('%d %b %Y, %I:%M %p')}\n"
    )

    if event.gps_lat and event.gps_lng:
        msg += f"Location: Verified\n\n"

    msg += (
        f"\nReceipt: {settings.RECEIPT_BASE_URL}/r/{event.receipt_token}\n"
        f"PIN: {event.receipt_pin}\n\n"
        f"Save this SMS as proof of payment."
    )
    return msg


def build_reminder_sms(member, workspace, reminder_type, amount_due):
    msg = (
        f"TapVerify — Reminder\n\n"
        f"Hello {member.name},\n"
        f"{workspace.name} meeting is coming up.\n\n"
        f"Your order payment: Ksh {amount_due:,.0f}\n"
    )

    if workspace.till_number:
        msg += f"Pay via M-Pesa Till: {workspace.till_number}\n"
    elif workspace.paybill_number:
        msg += f"Pay via M-Pesa Paybill: {workspace.paybill_number} (Acc: {workspace.account_number or member.member_code})\n"

    msg += f"\nOr bring cash to the meeting. See you there!"
    return msg
