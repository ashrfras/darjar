import 'package:flutter/material.dart';

IconData serviceCategoryIcon(String categoryId) {
  return switch (categoryId) {
    'home-maintenance' => Icons.handyman_rounded,
    'appliances-equipment' => Icons.devices_other_rounded,
    'cleaning-care' => Icons.cleaning_services_rounded,
    'transport-delivery' => Icons.local_shipping_rounded,
    'personal-family' => Icons.family_restroom_rounded,
    'other-services' => Icons.more_horiz_rounded,
    _ => Icons.miscellaneous_services_rounded,
  };
}
