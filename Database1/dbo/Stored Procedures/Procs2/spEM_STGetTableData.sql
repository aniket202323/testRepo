CREATE PROCEDURE dbo.spEM_STGetTableData 
  AS
 	 Declare @Tables Table (TableId Int,TableDesc nVarChar(100),KeyFieldTypeId Int,KeyFieldDesc nVarChar(100))
 	 Insert Into @Tables (TableId,TableDesc,KeyFieldTypeId,KeyFieldDesc) Values(1,'Events',9,'Production Unit')
 	 Insert Into @Tables (TableId,TableDesc,KeyFieldTypeId,KeyFieldDesc) Values(7,'Production Plan',59,'Production Execution Path')
 	 Declare @Fields Table (FieldId Int,TableId Int,FieldDesc nVarChar(100))
 	 Insert Into @Fields (FieldId,TableId,FieldDesc) Values(1,1,'Event_Status')
 	 Insert Into @Fields (FieldId,TableId,FieldDesc) Values(2,7,'PP_Status_Id')
 	 Declare @Values Table ( FieldId Int,ValueId Int,ValueDesc nVarChar(100))
 	 Insert Into @Values (FieldId,ValueId,ValueDesc)
 	  	  	 Select 1,ProdStatus_Id,ProdStatus_Desc
 	  	  	  	  from production_Status
 	 Insert Into @Values (FieldId,ValueId,ValueDesc) 
 	  	 Select 2,PP_Status_Id,PP_Status_Desc
 	  	  	 From production_Plan_Statuses
Select TableId,TableDesc,KeyFieldTypeId,KeyFieldDesc from @Tables
Select FieldId,TableId,FieldDesc From @Fields
Select FieldId,ValueId,ValueDesc From @Values order by FieldId,ValueDesc
