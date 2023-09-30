
/*
-------------------------------------------------------------------------
Name		spLocal_STLS_parmsel_ProdUnitDesc1
-------------------------------------------------------------------------
Modified 	Vinayal Pate
Date		02/12/2008
Build #8
Change		Use Proficy 'User Defined' Properties

Modified  Allen Duncan
Date        01/25/2012
Change    Change Query for Pu_desc to use joins to support change in proficy 5.x table_fields
          table addition of new tableid field for UDPs
          Version: 1.2
-------------------------------------------------------------------------
*/




Create  PROCEDURE [dbo].[spLocal_STLS_parmsel_ProdUnitDesc1]

	--Parameters
	@STLS_Component VARCHAR(10)
AS

/*
SELECT DISTINCT Prod_Units.PU_Id,Prod_Units.PL_Id,Prod_Units.Master_Unit,Prod_Units.Comment_Id,Prod_Units.PU_Desc
FROM Prod_Units
JOIN Comments ON Prod_Units.Comment_Id = Comments.Comment_Id
WHERE 
	(Comments.Comment_Text LIKE '%STLS=STLS/%'
		OR Comments.Comment_Text LIKE @STLS_Component)

	AND Prod_Units.Master_Unit IS NULL
*/


If @STLS_Component = '%STLS=LS/%'	
	BEGIN				-- List of Line Status Enabled Master Units

	SELECT DISTINCT PU.PU_Desc, PU.Master_Unit, Table_Fields.Table_Field_Desc
           FROM Prod_Units AS PU INNER JOIN Table_Fields_Values AS TFV ON PU.PU_Id = TFV.KeyId INNER JOIN
                Tables AS T ON TFV.TableId = T.TableId INNER JOIN Table_Fields ON TFV.Table_Field_Id = 
                Table_Fields.Table_Field_Id AND T.TableId = Table_Fields.TableId INNER JOIN Table_Fields_Values 
                ON Table_Fields.Table_Field_Id = Table_Fields_Values.Table_Field_Id AND CAST(TFV.KeyId AS varchar)
                 = Table_Fields_Values.Value
           WHERE (T.TableName = 'Prod_units') AND (PU.Master_Unit IS NULL) AND (Table_Fields.Table_Field_Desc = 'STLS_LS_MASTER_UNIT_ID') 
           Order by PU.PU_DESC
	END
ELSE IF @STLS_Component = '%STLS=ST/%'
	BEGIN				-- List of Crew Schedule Enabled Master Units

	SELECT DISTINCT PU.PU_Desc, PU.Master_Unit, Table_Fields.Table_Field_Desc
           FROM Prod_Units AS PU INNER JOIN Table_Fields_Values AS TFV ON PU.PU_Id = TFV.KeyId INNER JOIN
                Tables AS T ON TFV.TableId = T.TableId INNER JOIN Table_Fields ON TFV.Table_Field_Id = 
                Table_Fields.Table_Field_Id AND T.TableId = Table_Fields.TableId INNER JOIN Table_Fields_Values 
                ON Table_Fields.Table_Field_Id = Table_Fields_Values.Table_Field_Id AND CAST(TFV.KeyId AS varchar)
                 = Table_Fields_Values.Value
           WHERE (T.TableName = 'Prod_units') AND (PU.Master_Unit IS NULL) AND (Table_Fields.Table_Field_Desc = 'STLS_ST_MASTER_UNIT_ID') 
           Order by PU.PU_DESC
	END
	

