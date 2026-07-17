# Generated manually

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('orders', '0005_alter_order_payment_gateway'),
    ]

    operations = [
        migrations.AlterField(
            model_name='order',
            name='payment_gateway',
            field=models.CharField(choices=[('khalti', 'Khalti'), ('stripe', 'Stripe'), ('esewa', 'eSewa')], max_length=20),
        ),
    ]
