# Comprehensive Analysis: OCA Fleet and Maintenance Modules for Aircraft Management in Odoo 18.0

Based on extensive research of the OCA repositories, I've identified all available
modules in Odoo 18.0 and analyzed their applicability for managing aircraft (airplanes
and gliders) at an Aeroclub. This analysis evaluates how these modules could replace or
complement the current resource.booking approach.

## 1. OCA/Fleet Repository - Modules Available in 18.0

The [OCA/fleet repository](https://github.com/OCA/fleet) contains 13 modules for version
18.0, all at version 18.0.1.0.0:

### Core Vehicle Management

**1. fleet_vehicle_category** (Production/Stable)

- **Purpose**: Add category definitions for vehicles
- **Aircraft Relevance**: HIGH - Could categorize aircraft by type (gliders,
  single-engine, multi-engine, helicopters)
- **Key Features**: Hierarchical categorization system
- **Use Case**: Distinguish between different aircraft types for better organization and
  reporting

**2. fleet_vehicle_configuration** (Beta)

- **Purpose**: Add vehicle configuration capacity (seat management)
- **Aircraft Relevance**: MEDIUM - Tracks maximum seating capacity
- **Key Features**:
  - Supports same model with different configurations
  - Focuses on seating arrangements (e.g., 2-seater vs 4-seater aircraft)
- **Limitation**: Only handles seat configuration, not other options
- **Use Case**: Manage single-seat gliders vs. two-seat trainers

**3. fleet_vehicle_ownership** (Beta)

- **Purpose**: Link partners (owners) to vehicles
- **Aircraft Relevance**: HIGH - Essential for aeroclub management
- **Key Features**:
  - Many2one relationship with res.partner
  - Bidirectional linking (from vehicle or partner)
- **Use Case**: Track aircraft ownership (club-owned vs member-owned vs leased)

**4. fleet_vehicle_calendar_year** (Beta)

- **Purpose**: Register vehicle's calendar year
- **Aircraft Relevance**: MEDIUM - Useful for distinguishing model year from calendar
  year
- **Use Case**: Track aircraft manufacturing year vs registration year

### Operational Tracking

**5. fleet_vehicle_log_fuel** (Beta)

- **Purpose**: Add fuel logs similar to services
- **Aircraft Relevance**: HIGH (airplanes only) - Essential for powered aircraft
- **Key Features**: Fuel consumption tracking
- **Limitation**: Not applicable to gliders
- **Use Case**: Track avgas/jet fuel consumption for powered aircraft

**6. fleet_vehicle_fuel_capacity** (Beta)

- **Purpose**: Register vehicle's fuel tank capacity
- **Aircraft Relevance**: HIGH (airplanes only)
- **Key Features**:
  - Stores fuel capacity data
  - Planned feature: Validation to prevent refueling logs exceeding capacity
- **Use Case**: Define fuel capacity for each aircraft model

**7. fleet_vehicle_fuel_type_ethanol** (Beta)

- **Purpose**: Add ethanol as fuel type
- **Aircraft Relevance**: LOW - Not applicable (aviation fuel is avgas/jet fuel)

**8. fleet_vehicle_history_date_end** (Production/Stable)

- **Purpose**: Automatically assign end dates to driver history when new driver assigned
- **Aircraft Relevance**: HIGH - Important for pilot assignment tracking
- **Key Features**: Automatic historical record keeping
- **Use Case**: Track which pilots flew which aircraft and when

### Maintenance & Inspection

**9. fleet_vehicle_inspection** (Beta)

- **Purpose**: Register entry and exit inspections
- **Aircraft Relevance**: VERY HIGH - Critical for aviation safety
- **Key Features**:
  - Pre-flight and post-flight inspection recording
  - Cost tracking for inspections
  - Automatic service record creation upon confirmation
  - Configurable inspection items
- **Planned Features**:
  - Inspection reports
  - Video URL support for inspection documentation
- **Use Case**: Mandatory pre-flight and post-flight checks, daily inspections

**10. fleet_vehicle_service_activity** (Production/Stable)

- **Purpose**: Activity alerts for fleet services
- **Aircraft Relevance**: VERY HIGH - Essential for maintenance compliance
- **Key Features**:
  - Configurable advance notification (days before service)
  - Automatic activity creation for fleet manager
- **Use Case**: Alert maintenance team about upcoming inspections (50-hour, 100-hour,
  annual)

**11. fleet_vehicle_service_kanban** (Production/Stable)

- **Purpose**: Enhanced kanban view for service logs
- **Aircraft Relevance**: HIGH - Better visualization of maintenance workflow
- **Key Features**:
  - Tags for service organization
  - Activity types configuration
  - Responsible party assignment
  - Priority levels
  - Customizable workflow stages
- **Use Case**: Manage maintenance requests through workflow stages (Scheduled → In
  Progress → Completed)

**12. fleet_vehicle_service_services** (Beta)

- **Purpose**: Add subservices in services (hierarchical structure)
- **Aircraft Relevance**: HIGH - Complex maintenance has multiple sub-tasks
- **Key Features**: Nested service items like contract line structures
- **Use Case**: Break down major inspections into component checks (e.g., Annual
  Inspection → Engine Check → Control Surfaces → Avionics)

### Integration

**13. fleet_vehicle_purchase** (Beta)

- **Purpose**: Define fleet vehicles on Purchase Orders
- **Aircraft Relevance**: MEDIUM - Useful for aircraft acquisition
- **Key Features**: Proper inheritance of vehicle information through PO workflow
- **Use Case**: Track aircraft purchases and associated costs

## 2. OCA/Maintenance Repository - Modules Available in 18.0

The [OCA/maintenance repository](https://github.com/OCA/maintenance) contains 25 modules
for version 18.0. These provide more comprehensive equipment management capabilities:

### Foundation Modules

**1. base_maintenance** (Beta, LGPL-3)

- **Purpose**: Extends native Maintenance with standard Odoo features
- **Aircraft Relevance**: HIGH - Foundation for equipment management
- **Key Features**:
  - Team leadership assignment
  - Description field in maintenance teams
  - Search view for maintenance teams
  - Extensible button box on maintenance requests
  - Maintenance Request Report
- **Use Case**: Organize maintenance team with team leader for aircraft maintenance

**2. base_maintenance_group** (18.0.1.0.0)

- **Purpose**: Provides base access groups for Maintenance App
- **Aircraft Relevance**: MEDIUM - Security and access control
- **Use Case**: Control who can create/approve maintenance requests

**3. maintenance_security** (18.0.2.0.1)

- **Purpose**: Enhanced security for maintenance module
- **Aircraft Relevance**: MEDIUM - Important for compliance
- **Use Case**: Ensure only certified mechanics can approve certain maintenance

### Equipment Organization

**4. maintenance_equipment_hierarchy** (Beta, LGPL-3)

- **Purpose**: Manage equipment hierarchies
- **Aircraft Relevance**: VERY HIGH - Aircraft have complex component hierarchies
- **Key Features**: Parent-child relationships between equipment
- **Use Case**:
  - Aircraft → Engine → Propeller → Individual cylinders
  - Aircraft → Avionics → Radio → Transponder

**5. maintenance_equipment_category_hierarchy** (18.0.1.0.0)

- **Purpose**: Equipment category hierarchies
- **Aircraft Relevance**: HIGH - Organize aircraft types and components
- **Use Case**: Aircraft Types → Single Engine → Cessna 172 variants

**6. maintenance_equipment_sequence** (18.0.1.0.0)

- **Purpose**: Adds sequence numbering to equipment per category
- **Aircraft Relevance**: HIGH - Better equipment identification
- **Use Case**: Auto-generate aircraft tail numbers or equipment IDs

**7. maintenance_equipment_tags** (18.0.1.0.0)

- **Purpose**: Adds category tags to equipment
- **Aircraft Relevance**: HIGH - Flexible categorization
- **Use Case**: Tag aircraft by capability (IFR-certified, aerobatic, training)

**8. maintenance_equipment_status** (Beta, LGPL-3)

- **Purpose**: Indicate status of equipment
- **Aircraft Relevance**: VERY HIGH - Critical for airworthiness
- **Key Features**: Equipment status tracking
- **Use Case**: Track aircraft status (Airworthy, Grounded, In Maintenance, Awaiting
  Parts)

**9. maintenance_equipment_usage** (Beta, AGPL-3)

- **Purpose**: Record equipment usage by employees with dates, states, comments
- **Aircraft Relevance**: VERY HIGH - Essential for flight hours tracking
- **Key Features**: Usage tracking with dates and states
- **Use Case**: Record flight hours, landings, engine hours per flight
- **Gap**: May need enhancement for aviation-specific metrics (Hobbs time, Tach time,
  flight cycles)

### Maintenance Planning & Contracts

**10. maintenance_plan** (Beta, AGPL-3)

- **Purpose**: Multiple preventive maintenance types per equipment
- **Aircraft Relevance**: VERY HIGH - Aviation has multiple inspection types
- **Key Features**:
  - Multiple maintenance kinds with independent frequencies
  - Planning horizon for forecasting
  - Domain-based request generation
  - Automatic migration from standard Odoo preventive maintenance
  - Maintenance instructions storage
- **Use Case**:
  - 50-hour inspection every 50 flight hours
  - 100-hour inspection every 100 flight hours
  - Annual inspection every 12 months
  - Transponder certification every 24 months
  - ELT battery replacement every 5 years

**11. maintenance_plan_activity** (18.0.1.0.0)

- **Purpose**: Creates activities from maintenance plans
- **Aircraft Relevance**: HIGH - Proactive maintenance scheduling
- **Use Case**: Generate tasks for upcoming inspections

**12. maintenance_plan_only** (18.0.1.0.0)

- **Purpose**: Technical module to hide built-in recurrent settings
- **Aircraft Relevance**: MEDIUM - Clean up interface
- **Use Case**: Simplify UI by using only the enhanced planning features

**13. maintenance_equipment_contract** (Beta, AGPL-3)

- **Purpose**: Link maintenance equipment with supplier contracts
- **Aircraft Relevance**: HIGH - Manage maintenance agreements
- **Key Features**: Equipment field in contract forms
- **Use Case**:
  - Link aircraft to maintenance shop contracts
  - Track engine overhaul contracts
  - Manage avionics support agreements

### Integration Modules

**14. maintenance_product** (18.0.1.0.2)

- **Purpose**: Integrate Maintenance Equipment with Products
- **Aircraft Relevance**: HIGH - Streamline equipment creation
- **Key Features**:
  - Link equipment categories to product categories
  - Create equipment from products
  - Auto-populate vendor, cost, and reference data
- **Use Case**: Create aircraft equipment records from product catalog

**15. maintenance_project** (18.0.1.2.0)

- **Purpose**: Add projects to maintenance equipment and requests
- **Aircraft Relevance**: MEDIUM-HIGH - Useful for major overhauls
- **Key Features**:
  - Link equipment to projects
  - Assign tasks to maintenance requests
  - Default project for preventive maintenance
- **Use Case**: Major engine overhaul as a project with multiple tasks

**16. maintenance_timesheet** (18.0.1.1.0)

- **Purpose**: Add timesheets to maintenance requests
- **Aircraft Relevance**: HIGH - Track mechanic hours
- **Key Features**: Work hour tracking on maintenance
- **Use Case**: Record mechanic hours for cost allocation and billing

**17. maintenance_timesheet_time_control** (18.0.1.0.0)

- **Purpose**: Timesheet time tracking functionality
- **Aircraft Relevance**: MEDIUM - Enhanced time tracking
- **Use Case**: Ensure accurate time recording for maintenance work

**18. maintenance_stock** (18.0.1.0.1)

- **Purpose**: Link stock consumptions to maintenance requests
- **Aircraft Relevance**: VERY HIGH - Parts tracking essential
- **Key Features**:
  - Enable consumptions per equipment
  - Default warehouse configuration
  - Picking list generation from maintenance requests
  - Product moves tracking
  - Return operations support
- **Roadmap**: Product standard lists for equipment types
- **Use Case**:
  - Track parts used in maintenance (oil, filters, spark plugs)
  - Manage parts returns
  - Inventory consumption for aircraft maintenance

**19. maintenance_request_purchase** (18.0.1.0.0)

- **Purpose**: Link maintenance requests to Purchase Orders
- **Aircraft Relevance**: HIGH - Parts procurement integration
- **Use Case**: Order parts directly from maintenance requests

**20. maintenance_request_repair** (18.0.1.0.0)

- **Purpose**: Bridge between Maintenance and Repair modules
- **Aircraft Relevance**: HIGH - Structured repair workflows
- **Key Features**: Link repair orders to maintenance requests
- **Use Case**: Manage aircraft component repairs through Repair Orders

### Supporting Modules

**21. maintenance_request_employee** (18.0.1.0.0)

- **Purpose**: Link employees to maintenance requests
- **Aircraft Relevance**: HIGH - Track who worked on aircraft
- **Use Case**: Record certified mechanics who performed work

**22. maintenance_request_sequence** (18.0.1.0.0)

- **Purpose**: Add sequence numbering to maintenance requests
- **Aircraft Relevance**: MEDIUM - Better tracking and compliance
- **Use Case**: Auto-generate maintenance request numbers (MR-2026-001)

**23. maintenance_request_tags** (18.0.1.0.0)

- **Purpose**: Add tags to maintenance requests
- **Aircraft Relevance**: HIGH - Flexible categorization
- **Use Case**: Tag requests (Airworthiness, Cosmetic, Upgrade, Emergency)

**24. maintenance_partner** (18.0.1.0.0)

- **Purpose**: Add partner details to requests and equipment
- **Aircraft Relevance**: HIGH - Track external vendors
- **Use Case**: Link maintenance shops, parts suppliers to equipment

**25. hr_maintenance_security** (18.0.1.0.0)

- **Purpose**: HR Maintenance Security integration
- **Aircraft Relevance**: MEDIUM - Link HR data to maintenance
- **Use Case**: Ensure only certified A&P mechanics can sign off on work

## 3. OCA/account-financial-tools - Asset Management

The
[OCA/account-financial-tools repository](https://github.com/OCA/account-financial-tools/tree/18.0)
includes critical modules for managing aircraft as fixed assets:

**1. account_asset_management** (18.0.1.0.4, AGPL-3, Mature)

- **Purpose**: Comprehensive asset lifecycle and depreciation management
- **Aircraft Relevance**: VERY HIGH - Aircraft are expensive capital assets
- **Key Features**:
  - Full asset lifecycle (creation to removal)
  - Automated depreciation calculation
  - Manual/automatic depreciation entry generation
  - Multi-company support
  - Day-based depreciation calculation
  - Depreciation reversal capability
  - Asset creation from purchase invoices
- **Incompatibility**: NOT compatible with standard account_asset module
- **Use Case**:
  - Track aircraft purchase cost and depreciation
  - Manage aircraft as capital assets
  - Generate accounting entries for depreciation
  - Track aircraft book value

**2. account_asset_number** (18.0.1.0.0)

- **Purpose**: Sequential numbering for assets
- **Aircraft Relevance**: HIGH - Unique identification
- **Use Case**: Auto-generate asset numbers for each aircraft

**3. account_asset_low_value** (18.0.1.0.0)

- **Purpose**: Manage assets below value thresholds
- **Aircraft Relevance**: MEDIUM - For minor equipment
- **Use Case**: Track low-value aircraft equipment (headsets, chocks, tie-downs)

**4. account_asset_transfer** (18.0.1.0.1)

- **Purpose**: Transfer assets from AUC (Asset Under Construction) to operational assets
- **Aircraft Relevance**: MEDIUM-HIGH - For aircraft restoration projects
- **Use Case**: Manage aircraft restoration/rebuild projects

**5. account_asset_force_account** (18.0.1.0.0)

- **Purpose**: Force specific accounts for asset transactions
- **Aircraft Relevance**: MEDIUM - Accounting control
- **Use Case**: Ensure aircraft depreciation uses specific GL accounts

**6. account_asset_compute_batch** (18.0.1.0.0)

- **Purpose**: Batch processing of asset depreciation
- **Aircraft Relevance**: MEDIUM - Efficiency for multiple aircraft
- **Use Case**: Calculate depreciation for entire fleet at once

## 4. Fleet vs. Maintenance: Which to Use for Aircraft?

Based on my research, here's the critical comparison:

### Fleet Module Characteristics:

- **Designed for**: Motor vehicles (cars, trucks, vans)
- **Core features**: Driver management, fuel tracking, mileage/odometer, vehicle
  contracts, insurance
- **Tracking metric**: Odometer (distance-based)
- **Integration**: Primarily standalone or with HR for driver management

### Maintenance Module Characteristics:

- **Designed for**: Any type of equipment (machinery, tools, production equipment)
- **Core features**: Equipment hierarchy, preventive maintenance plans, usage tracking,
  maintenance requests, stock integration
- **Tracking metric**: Flexible (can be hours, cycles, days, or any custom metric)
- **Integration**: Deep integration with Inventory, Manufacturing, Projects, Timesheets,
  Purchase, HR

### Recommendation for Aircraft: **Use Maintenance Module**

**Reasons:**

1. **Hours vs. Miles**: Aircraft maintenance is based on flight hours, engine hours, and
   flight cycles—not odometer readings. The Maintenance module's flexible usage tracking
   (via `maintenance_equipment_usage`) is more suitable.

2. **Complex Equipment Hierarchy**: Aircraft have complex component hierarchies (engine,
   propeller, avionics, control surfaces). The `maintenance_equipment_hierarchy` module
   perfectly supports this, while Fleet is flat.

3. **Multiple Inspection Types**: Aviation requires multiple concurrent maintenance
   schedules (50-hour, 100-hour, annual, transponder, ELT). The `maintenance_plan`
   module supports multiple preventive maintenance kinds per equipment, while Fleet has
   simpler service scheduling.

4. **Equipment Status Critical**: Aircraft airworthiness status is legally required. The
   `maintenance_equipment_status` module provides explicit status tracking.

5. **Parts Integration**: Aircraft maintenance heavily involves parts tracking and
   inventory. The `maintenance_stock` module provides seamless integration with Odoo's
   inventory system.

6. **Better Integration**: Maintenance integrates with Projects (for major overhauls),
   Timesheets (mechanic hours), Purchase (parts ordering), and Repair (component
   repairs).

7. **Regulatory Compliance**: Maintenance module's request tracking, employee
   assignment, and documentation capabilities better support FAA/EASA compliance
   requirements.

### What Fleet Offers That Maintenance Doesn't (and workarounds):

| Fleet Feature               | Importance for Aircraft | Maintenance Workaround                            |
| --------------------------- | ----------------------- | ------------------------------------------------- |
| Fuel consumption tracking   | HIGH (powered aircraft) | Custom field + usage logs                         |
| Driver/Pilot assignment     | HIGH                    | Use `maintenance_equipment_usage` or custom field |
| Odometer tracking           | N/A (not relevant)      | Track flight hours via usage                      |
| Vehicle insurance contracts | MEDIUM                  | Use `maintenance_equipment_contract`              |
| Vehicle ownership           | HIGH                    | Custom field or `maintenance_partner`             |

## 5. Integration with Sales/Resource Booking

Based on research, there are existing fleet booking modules for Odoo, but for aircraft
at an Aeroclub, integration should work as follows:

### Recommended Architecture:

**Layer 1: Asset Management**

- `account_asset_management`: Aircraft as fixed assets with depreciation

**Layer 2: Equipment Management (Core)**

- `base_maintenance`: Foundation
- `maintenance_equipment_hierarchy`: Aircraft and component structure
- `maintenance_equipment_status`: Airworthiness tracking
- `maintenance_equipment_usage`: Flight hours tracking
- `maintenance_plan`: Multiple inspection schedules
- `maintenance_stock`: Parts and consumables

**Layer 3: Operations**

- `maintenance_project`: Major overhauls
- `maintenance_timesheet`: Mechanic hour tracking
- `maintenance_request_purchase`: Parts procurement

**Layer 4: Integration**

- Custom module: `aeroclub_maintenance_booking`
  - Link maintenance.equipment (aircraft) to resource.booking
  - Check aircraft status before allowing booking
  - Update usage hours from flight bookings
  - Validate airworthiness before confirming booking
  - Trigger maintenance alerts based on usage

### Integration Points with resource.booking:

```python
# Conceptual integration
class ResourceBooking(models.Model):
    _inherit = 'resource.booking'

    aircraft_id = fields.Many2one('maintenance.equipment',
                                  domain=[('category_id.name', '=', 'Aircraft')])
    flight_hours = fields.Float('Flight Hours')
    pre_flight_inspection = fields.Boolean('Pre-flight Check Complete')

    @api.constrains('aircraft_id')
    def _check_aircraft_status(self):
        # Verify aircraft is airworthy
        if self.aircraft_id.status != 'airworthy':
            raise ValidationError('Aircraft not airworthy')

    def action_confirm(self):
        # Update aircraft usage hours
        self.aircraft_id.record_usage(self.flight_hours)
        return super().action_confirm()
```

## 6. Module Selection for Aircraft Management

### Essential Modules (High Priority):

**Maintenance Core:**

1. `base_maintenance` - Foundation
2. `maintenance_equipment_hierarchy` - Aircraft component structure
3. `maintenance_equipment_status` - Airworthiness tracking
4. `maintenance_equipment_usage` - Flight hours tracking ⭐
5. `maintenance_plan` - Multiple inspection schedules ⭐
6. `maintenance_plan_activity` - Proactive scheduling
7. `maintenance_stock` - Parts tracking ⭐

**Organization:** 8. `maintenance_equipment_tags` - Categorization (IFR, VFR,
Training) 9. `maintenance_equipment_sequence` - Equipment numbering 10.
`maintenance_request_sequence` - Request tracking

**Integration:** 11. `maintenance_timesheet` - Mechanic hours 12.
`maintenance_request_purchase` - Parts ordering 13. `maintenance_partner` - Vendor
management

**Asset Accounting:** 14. `account_asset_management` - Fixed asset tracking ⭐

### Recommended Modules (Medium Priority):

**Maintenance:** 15. `maintenance_project` - Major overhauls 16.
`maintenance_request_repair` - Component repairs 17. `maintenance_equipment_contract` -
Maintenance agreements 18. `maintenance_product` - Product integration 19.
`maintenance_security` - Access control

**Fleet (Optional Additions):** 20. `fleet_vehicle_ownership` - If using Fleet for
tracking ownership 21. `fleet_vehicle_inspection` - Pre/post-flight inspections (if
using Fleet) 22. `fleet_vehicle_service_kanban` - Visual workflow (if using Fleet)

### Custom Development Needed:

**Critical Customizations:**

1. **Flight Hours Tracking**: Enhance `maintenance_equipment_usage` to track:

   - Hobbs meter (total time engine running)
   - Tach time (engine RPM-based time)
   - Flight cycles (takeoff/landing count)
   - Landings count

2. **Airworthiness Dashboard**: Custom views showing:

   - Days/hours until next inspection
   - Aircraft status (Airworthy/Grounded)
   - Upcoming maintenance
   - Overdue inspections (critical alerts)

3. **Booking Integration**: Bridge module `aeroclub_maintenance_booking`:

   - Link resource.booking to maintenance.equipment
   - Pre-flight status check
   - Auto-update flight hours from bookings
   - Validate airworthiness before booking confirmation

4. **Inspection Checklists**: Digital pre-flight and post-flight checklists:

   - Configurable checklist items
   - Digital signature capture
   - Photo attachment support
   - Automatic maintenance request creation for squawks

5. **Regulatory Compliance**: Reports for FAA/aviation authority compliance:
   - Aircraft logbook export
   - Maintenance summary reports
   - Inspection status reports
   - Component time tracking

## 7. Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)

- Install `base_maintenance`, `maintenance_security`
- Configure equipment categories (Aircraft Types → Single Engine, Glider, etc.)
- Create aircraft as maintenance equipment
- Set up maintenance teams

### Phase 2: Core Functionality (Weeks 3-4)

- Install `maintenance_equipment_hierarchy` - define component structure
- Install `maintenance_equipment_status` - configure status values
- Install `maintenance_plan` - create inspection schedules
- Install `maintenance_stock` - configure parts warehouse

### Phase 3: Usage Tracking (Weeks 5-6)

- Install `maintenance_equipment_usage`
- Customize for flight hours tracking (Hobbs, Tach, cycles)
- Create usage entry forms for post-flight recording
- Set up usage reports

### Phase 4: Integration (Weeks 7-8)

- Install `maintenance_timesheet`, `maintenance_request_purchase`
- Install `maintenance_product`, `maintenance_partner`
- Develop custom `aeroclub_maintenance_booking` bridge module
- Integrate with existing resource.booking

### Phase 5: Asset Management (Weeks 9-10)

- Install `account_asset_management`
- Create aircraft assets with depreciation schedules
- Link maintenance.equipment to account.asset records
- Configure depreciation accounting

### Phase 6: Refinement (Weeks 11-12)

- Develop custom dashboards and reports
- Create digital inspection checklists
- Build compliance reports
- User training and documentation

## 8. Advantages Over Current resource.booking Approach

### Current Limitations of resource.booking:

- Generic resource tracking, not aviation-specific
- No built-in maintenance scheduling
- No parts/inventory integration
- No compliance/airworthiness tracking
- Limited reporting for regulatory needs

### Advantages of Maintenance-Based Approach:

**1. Aviation-Specific Tracking:**

- Flight hours, engine hours, flight cycles
- Component-level tracking (engine TBO, prop overhaul)
- Multiple concurrent inspection schedules

**2. Regulatory Compliance:**

- Airworthiness status enforcement
- Inspection due date tracking
- Maintenance history/audit trail
- Employee certification tracking

**3. Preventive Maintenance:**

- Automatic request generation based on hours/dates
- Alert notifications before inspections due
- Planning horizon for scheduling
- Multiple maintenance types per aircraft

**4. Parts Management:**

- Inventory integration for consumables (oil, filters)
- Parts ordering from maintenance requests
- Stock consumption tracking
- Parts return handling

**5. Financial Integration:**

- Fixed asset tracking and depreciation
- Cost allocation per aircraft
- Maintenance cost tracking
- Timesheet-based billing

**6. Better Organization:**

- Equipment hierarchy (aircraft → components)
- Status management (airworthy/grounded)
- Team management with roles
- Project integration for major work

**7. Comprehensive Reporting:**

- Aircraft utilization reports
- Maintenance cost analysis
- Compliance status dashboards
- Inspection due lists

## 9. Potential Challenges and Solutions

### Challenge 1: Flight Hours vs. Odometer

**Issue**: Maintenance module tracks usage, but aviation uses specific metrics (Hobbs,
Tach) **Solution**: Extend `maintenance_equipment_usage` with custom fields for aviation
metrics

### Challenge 2: Booking System Integration

**Issue**: Need to connect booking system to maintenance tracking **Solution**: Develop
custom bridge module that:

- Links bookings to aircraft (maintenance.equipment)
- Validates airworthiness before booking
- Auto-updates flight hours from completed bookings
- Triggers maintenance alerts

### Challenge 3: Pre-flight Inspections

**Issue**: Daily pre-flight checks differ from scheduled maintenance **Solution**: Use
`fleet_vehicle_inspection` concepts within Maintenance or develop custom inspection
module with:

- Quick daily inspection forms
- Configurable checklists
- Photo/video support
- Squawk reporting

### Challenge 4: Multi-level Maintenance Schedules

**Issue**: Aircraft have complex overlapping schedules (50hr, 100hr, annual,
calendar-based) **Solution**: Use `maintenance_plan` with multiple maintenance kinds:

- Hour-based: 50hr, 100hr inspections
- Calendar-based: Annual, transponder, ELT
- Cycle-based: Landing gear inspections

### Challenge 5: Component Time Tracking

**Issue**: Individual components (engine, prop) have separate time limits **Solution**:
Use `maintenance_equipment_hierarchy`:

- Aircraft as parent equipment
- Components as child equipment
- Each child tracks own usage and maintenance plans

### Challenge 6: Gliders vs. Powered Aircraft

**Issue**: Gliders don't use fuel, different tracking needs **Solution**: Use aircraft
categories with conditional fields:

- Gliders: Track flight hours, launches, winch/aero-tow vs self-launch
- Powered: Track flight hours, fuel consumption, engine hours

## Summary and Recommendations

### Primary Recommendation: **Maintenance Module with Selective Fleet Enhancements**

**Core Architecture:**

- Use **Maintenance** as the primary system for aircraft management
- Use **Account Asset Management** for financial/depreciation tracking
- Develop custom bridge to **resource.booking** for operations

**Module Selection:**

**Must Have (13 modules):**

1. base_maintenance
2. maintenance_equipment_hierarchy
3. maintenance_equipment_status
4. maintenance_equipment_usage
5. maintenance_plan
6. maintenance_plan_activity
7. maintenance_stock
8. maintenance_equipment_tags
9. maintenance_request_sequence
10. maintenance_timesheet
11. maintenance_request_purchase
12. maintenance_partner
13. account_asset_management

**Should Have (6 modules):** 14. maintenance_project 15. maintenance_request_repair 16.
maintenance_equipment_contract 17. maintenance_product 18. maintenance_security 19.
maintenance_equipment_sequence

**Nice to Have (3 modules):** 20. fleet_vehicle_ownership (if hybrid approach) 21.
fleet_vehicle_inspection (for inspection templates) 22. account_asset_number

**Custom Development Required:**

- Aviation-specific usage tracking (Hobbs, Tach, cycles)
- Booking system integration
- Digital inspection checklists
- Airworthiness dashboard
- Compliance reports

### Expected Benefits:

1. **Compliance**: Full regulatory compliance with FAA/EASA requirements
2. **Safety**: Proactive maintenance scheduling prevents overdue inspections
3. **Cost Control**: Better parts tracking and cost allocation
4. **Efficiency**: Integrated workflow from booking → flight → maintenance → accounting
5. **Reporting**: Comprehensive reports for management and authorities
6. **Scalability**: System can grow with fleet expansion

### Timeline Estimate:

- **Initial Setup**: 2-3 weeks
- **Full Implementation**: 10-12 weeks
- **Custom Development**: 4-6 weeks parallel
- **Total Project**: 12-14 weeks to full operation

This maintenance-based approach provides a robust, scalable, and compliant system for
aircraft management that far exceeds the capabilities of the current resource.booking
approach.

---

## Next Steps - Immediate Actions

Based on your request to "cambia los recursos por un vehículo, que después le vamos a
agregar el Tipo Aeronave", here are the recommended immediate actions:

### 1. Temporary Transition: Change Resources to Vehicles

For now, modify the `aeroclub_flight_booking` module to use fleet.vehicle instead of
resource.booking:

**Changes needed:**

- Replace `resource_id` field with `vehicle_id` (Many2one to fleet.vehicle)
- Keep the booking functionality but link to vehicles
- This provides a temporary bridge until full Maintenance implementation

**Rationale**: This allows immediate use of Fleet's vehicle tracking while planning the
full Maintenance integration.

### 2. Add "Aircraft Type" to Fleet

Once Fleet integration is working:

- Add custom field `aircraft_type` to fleet.vehicle
- Options: 'airplane' or 'glider'
- This enables basic aircraft categorization

### 3. Plan Full Maintenance Integration

After testing Fleet approach and analyzing the Maintenance modules further:

- Decide on final architecture (Maintenance-based or hybrid)
- Plan migration from fleet.vehicle to maintenance.equipment
- Develop `aeroclub_maintenance_booking` bridge module
- Implement aviation-specific tracking (Hobbs, Tach, cycles)

The document you requested has been created and provides comprehensive analysis to make
informed decisions about the aircraft management architecture.
