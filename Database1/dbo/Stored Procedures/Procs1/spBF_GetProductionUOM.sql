CREATE PROCEDURE [dbo].[spBF_GetProductionUOM]
@UnitList text = NULL
AS 
DECLARE @Units TABLE  (RowID 	  	  	 int IDENTITY,
 	  	  	  	 PUId int NULL ,
 	  	  	  	 LineName nVarChar(100) NULL,
 	  	  	  	 LineId int NULL, 
 	  	  	  	 PUDesc nVarChar(100) NULL  
 	  	  	 
)
DECLARE 	 -- General
 	  	 @Rows 	  	  	  	  	  	  	 int,
 	  	 @UnitRows 	  	  	  	  	  	 int,
 	  	 @Row 	  	  	  	  	  	  	 int,
 	  	 @CurrentPUID 	  	  	  	  	 int,
 	  	 @ProductionType 	  	  	  	  	 tinyint,
 	  	 @ProductionVarId 	  	  	  	 int,
 	  	 @UOM 	  	  	  	 nvarchar(1000),
 	  	 @CurrentPudesc 	  	 nvarchar(1000)
Declare @UOMList table (
 	  	 Engg_Unit nvarchar(1000),
 	  	 PUId 	  	 int,
 	  	 PUdesc 	  	 nvarchar(1000))
IF (NOT @UnitList like '%<Root></Root>%' AND NOT @UnitList IS NULL)
  BEGIN
    IF (NOT @UnitList LIKE '%<Root>%')
    BEGIN 	 
      DECLARE @Text nVarChar(4000)
      SELECT @Text = N'UnitId;' + Convert(nVarChar(4000), @UnitList)
      INSERT INTO @Units (PUId) EXECUTE spDBR_Prepare_Table @Text
 	  END
    ELSE
    BEGIN
      INSERT INTO @Units (LineName, LineId, PUDesc, PUId) EXECUTE spDBR_Prepare_Table @UnitList
    END
  END
ELSE
  BEGIN
    INSERT INTO @Units (PUId, PUDesc) 
      SELECT DISTINCT pu_id, pu_desc 
 	   FROM prod_units WHERE pu_id > 0
  END
  SELECT @UnitRows 	 = Count(*) ,
 	    @Row 	  	 = 	 0 	 from @Units
--Check where is the production , from variable or events details
WHILE @Row <  @UnitRows
BEGIN
 	 SELECT @Row = @Row + 1
 	 SELECT @CurrentPUID = PUId  FROM @Units WHERE ROWID = @Row
 	 SELECT 	 @ProductionType 	  	  	  	 = Production_Type,
 	  	  	 @ProductionVarId 	  	  	 = Production_Variable,
 	  	  	 @CurrentPudesc = PU_Desc
 	 FROM dbo.Prod_Units WITH (NOLOCK)
 	 WHERE PU_Id = @CurrentPUID
 	 IF @ProductionType = 1
 	  	 BEGIN
 	  	  	  	  	 SELECT 	 @UOM = Eng_Units
 	  	  	  	  	 FROM 	 dbo.Variables WITH (NOLOCK) 
 	  	  	  	  	 WHERE 	 Var_Id = @ProductionVarId
 	  	 END
 	 ELSE
 	  	 BEGIN
 	  	  	 SELECT @UOM =es.Dimension_X_Eng_Units FROM dbo.Event_Configuration ec WITH (NOLOCK)  
 	  	  	 JOIN prod_units pu WITH (NOLOCK)  ON ec.pu_id = pu.pu_id
 	  	  	 JOIN Event_Subtypes es WITH (NOLOCK) ON ec.Event_Subtype_Id = es.Event_Subtype_Id
 	  	  	 WHERE pu.pu_id = @CurrentPUID and ec.ET_Id=1
 	  	  	 END
 	 INSERT INTO @UOMList (Engg_Unit,PUId,PUdesc) VALUES (@UOM,@CurrentPUID,@CurrentPudesc)
END
SELECT Coalesce(Engg_Unit,'Units') as UOM,PUId,PUdesc FROM @UOMList
