CREATE PROCEDURE dbo.spServer_CalcMgrGetEquipmentTypes
AS
select pu_id, Equipment_type from prod_units_Base where Equipment_Type is not null
