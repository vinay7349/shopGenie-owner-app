import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models

def backfill_existing_shops(apps, schema_editor):
    CustomUser = apps.get_model('accounts', 'CustomUser')
    Shop = apps.get_model('accounts', 'Shop')

    for user in CustomUser.objects.all():
        if not user.role:
            user.role = 'SHOP_OWNER'
            user.save(update_fields=['role'])

        # Ensure every existing owner has their single Shop instance
        if user.role == 'SHOP_OWNER' and not Shop.objects.filter(owner=user).exists():
            shop_title = user.shop_name.strip() if user.shop_name else f"{user.username}'s Mart"
            Shop.objects.create(
                owner=user,
                name=shop_title,
                category='Grocery & Supermarket',
                verification_status='VERIFIED',
                is_active=True
            )

class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Shop',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(db_index=True, max_length=200)),
                ('address', models.TextField(blank=True, default='')),
                ('category', models.CharField(default='Grocery & Supermarket', max_length=100)),
                ('phone', models.CharField(blank=True, default='', max_length=30)),
                ('business_hours', models.CharField(default='08:00 AM - 10:00 PM (Daily)', max_length=100)),
                ('description', models.TextField(blank=True, default='Neighbourhood retail storefront powered by ShopGenie POS.')),
                ('verification_status', models.CharField(choices=[('VERIFIED', 'Verified'), ('UNDER_REVIEW', 'Under Review'), ('PENDING', 'Pending Verification'), ('REJECTED', 'Rejected')], default='VERIFIED', max_length=30)),
                ('is_active', models.BooleanField(default=True)),
                ('rating', models.DecimalField(decimal_places=2, default=4.8, max_digits=3)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('owner', models.OneToOneField(help_text='The single authenticated Shop Owner who owns and manages this shop.', on_delete=django.db.models.deletion.CASCADE, related_name='owned_shop', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Shop',
                'verbose_name_plural': 'Shops',
                'db_table': 'shopgenie_shops',
            },
        ),
        migrations.AddField(
            model_name='customuser',
            name='role',
            field=models.CharField(choices=[('SHOP_OWNER', 'Shop Owner'), ('SHOP_WORKER', 'Shop Worker')], db_index=True, default='SHOP_OWNER', help_text='Backend-enforced user role: SHOP_OWNER or SHOP_WORKER.', max_length=20),
        ),
        migrations.AddField(
            model_name='customuser',
            name='assigned_shop',
            field=models.ForeignKey(blank=True, help_text='The shop this worker is assigned to. Only valid for SHOP_WORKER.', null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='workers', to='accounts.shop'),
        ),
        migrations.AddField(
            model_name='customuser',
            name='is_worker_active',
            field=models.BooleanField(default=True, help_text='Allows the owner to deactivate worker accounts immediately without deleting records.'),
        ),
        migrations.AddField(
            model_name='customuser',
            name='can_view_invoices',
            field=models.BooleanField(default=True, help_text='Permission for worker to view invoice history.'),
        ),
        migrations.AddField(
            model_name='customuser',
            name='can_confirm_bills',
            field=models.BooleanField(default=True, help_text='Permission for worker to accept checkout items and complete bills.'),
        ),
        migrations.AlterModelOptions(
            name='customuser',
            options={'verbose_name': 'Shopkeeper / Worker User', 'verbose_name_plural': 'Shopkeeper / Worker Users'},
        ),
        migrations.RunPython(backfill_existing_shops, migrations.RunPython.noop),
    ]
