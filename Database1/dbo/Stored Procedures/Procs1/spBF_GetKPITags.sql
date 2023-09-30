CREATE Procedure [dbo].[spBF_GetKPITags]
  	  @UnitList nvarchar(max)
AS
SET NoCount On
DECLARE @Units TABLE ( RowID int IDENTITY, UnitId int NULL)
DECLARE @Tags TABLE ( RowID int IDENTITY, UnitId int NULL, Name nvarchar(255), Historian nvarchar(255), TagId nvarchar(255), Description nvarchar(255), Units nvarchar(255))
-------------------------------------------------------------------------------------------------
-- Unit translation
-------------------------------------------------------------------------------------------------
If (@UnitList is Not Null)
  	  Set @UnitList = REPLACE(@UnitList, ' ', '')
if ((@UnitList is Not Null) and (LEN(@UnitList) = 0))
  	  Set @UnitList = Null
if (@UnitList is not null)
  	  begin
  	    	  insert into @Units (UnitId)
  	    	  select Id from [dbo].[fnCmn_IdListToTable]('Prod_Units',@UnitList,',')
  	  end
--Select * from @Units
-------------------------------------------------------------------------------------------------
-- Return the tag list
-------------------------------------------------------------------------------------------------
Insert into @Tags(UnitId, Name, Historian, TagId, Description, Units)
 SELECT      c.PU_Id, a.name,
             SUBSTRING( d.Name,1,CHARINDEX('.',d.name)-1) as Historian,
             SUBSTRING( d.Name,CHARINDEX('.',d.name)+1,LEN(d.name)) as TagId,
             a.Description, a.UnitOfMeasure
   from      Property_Equipment_EquipmentClass  a
   Join      Equipment b on b.EquipmentId = a.EquipmentId
   Left Join PAEquipment_Aspect_SOAEquipment c on c.Origin1EquipmentId = b.EquipmentId
   Left Join BinaryItem d on d.ItemId = a.ItemId
 where       a.ItemId is not null
   and       c.PU_Id in (Select UnitId from @Units)
   and       a.Class = 'VisualizedProperties'
 order by    c.PU_Id, Historian, TagId
Select UnitId, Name, Historian, TagId, Description, Units from @Tags
