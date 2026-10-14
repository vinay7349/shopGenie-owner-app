from django.urls import path
from .views import (
    RegisterView,
    CustomLoginView,
    CustomTokenRefreshView,
    UserProfileView,
    MyShopView,
    WorkerListCreateView,
    WorkerDetailView,
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='auth_register'),
    path('login/', CustomLoginView.as_view(), name='auth_login'),
    path('refresh/', CustomTokenRefreshView.as_view(), name='auth_refresh'),
    path('me/', UserProfileView.as_view(), name='auth_me'),
    path('my-shop/', MyShopView.as_view(), name='auth_my_shop'),
    path('workers/', WorkerListCreateView.as_view(), name='auth_workers'),
    path('workers/<int:pk>/', WorkerDetailView.as_view(), name='auth_worker_detail'),
]
