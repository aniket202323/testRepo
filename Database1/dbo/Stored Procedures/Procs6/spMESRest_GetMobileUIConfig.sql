Create Procedure [dbo].[spMESRest_GetMobileUIConfig] (
  @DisplayType varchar(200),
  @EquipmentGuid varchar(200))
AS
----------------------------------------------------------------------------
-- figure out what unit we are on and identify children
----------------------------------------------------------------------------
declare @EquipmentInfo table (TreeLevel int, PU_Id int, EquipId uniqueidentifier, ldap varchar(4000))
declare @PUId int
declare @Equip uniqueidentifier
declare @Parent uniqueidentifier
declare @ldap varchar(4000)
declare @EquipType varchar(255)
declare @EquipmentList VARCHAR(8000)  
select @PUId = PU_Id from PAEquipment_Aspect_SOAEquipment where Origin1EquipmentId = @EquipmentGuid
-- Figure out the base Ldap Address
set @ldap = ''
set @Equip = @EquipmentGuid
While (@Equip is not null)
  Begin
    select @EquipType=Type, @Parent=ParentEquipmentId from Equipment where EquipmentId = @Equip
    if (len(@ldap) > 0)
      set @ldap = @ldap + ','
    set @ldap = @ldap + 'CN=' + @EquipType + '-' + lower(CONVERT(varchar(50), @Equip))
    select @Equip = @Parent
  End
set @ldap = @ldap + ',CN=Equipment,CN=SOAProject,CN=Projects,OU=Publications,O=Proficy'
insert into @EquipmentInfo (TreeLevel, PU_Id, EquipId, ldap) values (0, @PUId, @EquipmentGuid, @ldap)
-- Find Child Equipment ???
Set @EquipmentList = null
Select @EquipmentList = COALESCE(@EquipmentList + ',', '') + '[' + ldap + ']'  from @EquipmentInfo order by TreeLevel 
----------------------------------------------------------------------------
-- Setup config tables, this should be in the database
----------------------------------------------------------------------------
declare @Displays table (DisplayId int, DisplayName varchar(50))
declare @Filters table (FilterId int, FilterName varchar(50))
declare @Config table (ConfigId int, ConfigName varchar(50))
declare @ConfigDisplays table (ConfigId int, DisplayId int)
declare @ConfigFilters table (ConfigId int, FilterId int, Filter varchar(255))
insert into @Displays (DisplayId, DisplayName) values (1, 'Property Values')
insert into @Displays (DisplayId, DisplayName) values (2, 'Event Details')
insert into @Displays (DisplayId, DisplayName) values (3, 'BOM')
insert into @Displays (DisplayId, DisplayName) values (4, 'Inventory')
insert into @Filters (FilterId, FilterName) values (1, 'EventTypes')
insert into @Filters (FilterId, FilterName) values (2, 'IncludeProdStatuses')
insert into @Filters (FilterId, FilterName) values (3, 'ExcludeProdStatuses')
insert into @Filters (FilterId, FilterName) values (4, 'IncludePOStatuses')
insert into @Filters (FilterId, FilterName) values (5, 'ExcludePOStatuses')
insert into @Filters (FilterId, FilterName) values (6, 'IncludeInventoryStatuses')
insert into @Filters (FilterId, FilterName) values (7, 'ExcludeInventoryStatuses')
insert into @Config (ConfigId, ConfigName) values (1, 'soe')
insert into @ConfigDisplays (ConfigId, DisplayId) values (1, 1)
insert into @ConfigDisplays (ConfigId, DisplayId) values (1, 2)
insert into @ConfigFilters (ConfigId, FilterId, Filter) values (1, 1, 'All')
insert into @ConfigFilters (ConfigId, FilterId, Filter) values (1, 2, 'Complete, Shipped')
insert into @Config (ConfigId, ConfigName) values (2, 'schedview')
insert into @ConfigDisplays (ConfigId, DisplayId) values (2, 2)
insert into @ConfigDisplays (ConfigId, DisplayId) values (2, 3)
insert into @ConfigDisplays (ConfigId, DisplayId) values (2, 4)
insert into @ConfigFilters (ConfigId, FilterId, Filter) values (2, 1, 'ProcessOrder')
insert into @ConfigFilters (ConfigId, FilterId, Filter) values (2, 5, 'Complete, Overproduced, Underproduced, Planning')
insert into @ConfigFilters (ConfigId, FilterId, Filter) values (2, 6, 'Complete')
----------------------------------------------------------------------------
-- Figure out the Sheet variables for each event type
----------------------------------------------------------------------------
declare @SheetId int
declare @Sheets table (EventType int, SheetId int, Props varchar(8000))
declare @Variables table (EventType int, VarOrder int, VarDesc varchar(255))
declare @Props VARCHAR(8000)  
--Find the Sheet Ids for this unit
insert into @Sheets (EventType, SheetId) values ( 1, (select top 1 sheet_id from sheets where Master_Unit = @PUId and Event_Type =  1)) --Production/MaterialLot
insert into @Sheets (EventType, SheetId) values ( 2, (select top 1 sheet_id from sheets where Master_Unit = @PUId and Event_Type =  2)) --Downtime
insert into @Sheets (EventType, SheetId) values ( 3, (select top 1 sheet_id from sheets where Master_Unit = @PUId and Event_Type =  3)) --Waste
insert into @Sheets (EventType, SheetId) values ( 4, (select top 1 sheet_id from sheets where Master_Unit = @PUId and Event_Type =  4)) --Product Change
insert into @Sheets (EventType, SheetId) values (14, (select top 1 sheet_id from sheets where Master_Unit = @PUId and Event_Type = 14)) --User Defined
insert into @Sheets (EventType, SheetId) values (19, (select top 1 sheet_id from sheets where Master_Unit = @PUId and Event_Type = 19)) --Process Order
insert into @Sheets (EventType, SheetId) values (22, (select top 1 sheet_id from sheets where Master_Unit = @PUId and Event_Type = 22)) --Uptime
insert into @Sheets (EventType, SheetId) values (31, (select top 1 sheet_id from sheets where Master_Unit = @PUId and Event_Type = 31)) --Segment Response
insert into @Sheets (EventType, SheetId) values (32, (select top 1 sheet_id from sheets where Master_Unit = @PUId and Event_Type = 32)) --Work Response
insert into @Variables (EventType, VarOrder, VarDesc)
  select s.EventType, sv.Var_Order, v.Var_Desc
    from @Sheets s
    join Sheet_Variables sv on sv.Sheet_Id = s.SheetId
    join Variables v on v.Var_Id = sv.Var_Id
Set @Props = null
Select @Props = COALESCE(@Props + ',', '') + '[' + VarDesc + ']'  from @Variables where EventType =  1 order by VarOrder 
update @Sheets set Props = @Props where EventType = 1
Set @Props = null
Select @Props = COALESCE(@Props + ',', '') + '[' + VarDesc + ']'  from @Variables where EventType =  2 order by VarOrder 
update @Sheets set Props = @Props where EventType = 2
Set @Props = null
Select @Props = COALESCE(@Props + ',', '') + '[' + VarDesc + ']'  from @Variables where EventType =  3 order by VarOrder 
update @Sheets set Props = @Props where EventType = 3
Set @Props = null
Select @Props = COALESCE(@Props + ',', '') + '[' + VarDesc + ']'  from @Variables where EventType =  4 order by VarOrder 
update @Sheets set Props = @Props where EventType = 4
Set @Props = null
Select @Props = COALESCE(@Props + ',', '') + '[' + VarDesc + ']'  from @Variables where EventType = 14 order by VarOrder 
update @Sheets set Props = @Props where EventType = 14
Set @Props = null
Select @Props = COALESCE(@Props + ',', '') + '[' + VarDesc + ']'  from @Variables where EventType = 19 order by VarOrder 
update @Sheets set Props = @Props where EventType = 19
Set @Props = null
Select @Props = COALESCE(@Props + ',', '') + '[' + VarDesc + ']'  from @Variables where EventType = 22 order by VarOrder 
update @Sheets set Props = @Props where EventType = 22
Set @Props = null
Select @Props = COALESCE(@Props + ',', '') + '[' + VarDesc + ']'  from @Variables where EventType = 31 order by VarOrder 
update @Sheets set Props = @Props where EventType = 31
Set @Props = null
Select @Props = COALESCE(@Props + ',', '') + '[' + VarDesc + ']'  from @Variables where EventType = 32 order by VarOrder 
update @Sheets set Props = @Props where EventType = 32
----------------------------------------------------------------------------
-- Return the final results
----------------------------------------------------------------------------
-- Equipment
select @EquipmentList
-- Displays
select d.DisplayId
  from @Config c
  join @ConfigDisplays cd on cd.ConfigId = c.ConfigId
  join @Displays d on d.DisplayId = cd.DisplayId
  where c.ConfigName like @DisplayType
-- Filters
select f.FilterId, cf.Filter
  from @Config c
  join @ConfigFilters cf on cf.ConfigId = c.ConfigId
  join @Filters f on f.FilterId = cf.FilterId
  where c.ConfigName like @DisplayType
-- Properties
select EventType, Props from @Sheets where Props is not null
