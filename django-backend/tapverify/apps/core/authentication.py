"""Bearer-token auth for secretaries.

Login issues a random token stored on the Secretary row.
Clients send:  Authorization: Bearer <token>
"""
from rest_framework import authentication, exceptions, permissions

from .models import Secretary


class IsSecretary(permissions.BasePermission):
    def has_permission(self, request, view):
        return isinstance(request.user, Secretary)


class SecretaryTokenAuthentication(authentication.BaseAuthentication):
    keyword = 'Bearer'

    def authenticate(self, request):
        header = authentication.get_authorization_header(request).decode('utf-8')
        if not header.startswith(f'{self.keyword} '):
            return None
        token = header[len(self.keyword) + 1:].strip()
        if not token:
            return None
        try:
            secretary = Secretary.objects.get(auth_token=token)
        except Secretary.DoesNotExist:
            raise exceptions.AuthenticationFailed('Invalid token')
        return (secretary, None)

    def authenticate_header(self, request):
        return self.keyword
