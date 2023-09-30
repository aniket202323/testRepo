--  spEMCC_GetSPCDefaults 552
Create Procedure dbo.spEMCC_GetSPCDefaults
@VarId Int
AS
Declare @PuId 	  	 Int,
 	  	 @MasterUnit 	 Int
SELECT @PuId = PU_Id FROM Variables WHERE Var_Id = @VarId
SELECT @MasterUnit = Master_Unit FROM Prod_Units WHERE PU_Id = @PuId
SELECT @MasterUnit = IsNull(@MasterUnit,@PuId)
DECLARE @EventTypes TABLE (ET_Id Int,ES_ID Int Null, PEI_Id int Null)
INSERT INTO @EventTypes (ET_Id) VALUES (0)
INSERT INTO @EventTypes (ET_Id,ES_ID)
 	 SELECT ET_Id,Event_Subtype_Id
 	 FROM  Event_configuration 
 	 WHERE PU_Id = @MasterUnit and ET_Id is not null 
DELETE FROM @EventTypes 
 	 WHERE Et_Id in (SELECT Et_Id FROM Event_Types WHERE Variables_Assoc <> 1)
If (SELECT count(*) FROM @EventTypes WHERE ET_Id = 4) > 0
 	 INSERT INTO  @EventTypes (ET_Id) VALUES (5)
If (SELECT count(*) FROM @EventTypes WHERE ET_Id = 19) > 0
 	 INSERT INTO  @EventTypes (ET_Id) VALUES (28)
INSERT INTO  @EventTypes (ET_Id,PEI_Id) 
 	  	 SELECT  17,PEI_Id
 	  	 FROM prdexec_inputs 
 	  	 WHERE PU_Id = @MasterUnit
SELECT SPC_Calculation_Type_Id, SPC_Calculation_Type_Desc FROM SPC_Calculation_Types 
  Order By SPC_Calculation_Type_Desc
--No CalcMgr DataSource for SPC children variables
SELECT DS_Id, DS_Desc FROM Data_Source
  WHERE Active = 1 and DS_Id <> 16
  Order By DS_Desc
SELECT Data_Type_Id, Data_Type_Desc 
  FROM Data_Type
  WHERE Data_Type_Id Not In ( 6,7,8,50)
  Order By Data_Type_Desc
SELECT DISTINCT TagData =  convert(nVarChar(10),et.ET_Id) + ',' +
 	 convert(nVarChar(10),isNull(et.Pei_Id,0)) + ','  +
 	 convert(nVarChar(10),isNull(et.ES_ID,0)),
     ET_Desc = ET_Desc + 
 	 CASE WHEN Event_Subtype_Desc IS NOT NULL Then '/' ELSE '' END + isnull(Event_Subtype_Desc,'') +
 	 CASE WHEN Input_Name IS NOT NULL Then '/' ELSE '' END + isnull(Input_Name,'')
  FROM @EventTypes et
  JOIN Event_Types et1 ON et.ET_Id = et1.ET_Id
  LEFT JOIN Event_Subtypes es on es.Event_Subtype_Id = et.ES_ID
  LEFT JOIN prdexec_inputs pei ON PEI.PEI_Id = et.PEI_Id
  Order By ET_Desc
SELECT  	 TagData =  convert(nVarChar(10),Event_Type) + ',' +
 	 convert(nVarChar(10),isNull(PEI_Id,0)) + ','  +
 	 convert(nVarChar(10),isNull(Event_Subtype_Id,0))
 	 FROM Variables 
 	 WHERE Var_Id = @VarId
