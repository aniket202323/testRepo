
/*
1 - List of all Areas(Departments)                                          EXECUTE [spBF_GetPlantModelByAsset] null, 1
2 - List of all lines of a Departments                                      EXECUTE [spBF_GetPlantModelByAsset] null, 2
3 - List of all unit of a lines                                             EXECUTE [spBF_GetPlantModelByAsset] null, 3
4 - List of all group of a unit                                             EXECUTE [spBF_GetPlantModelByAsset] null, 4
5 - List of all variable of a group                                         EXECUTE [spBF_GetPlantModelByAsset] null, 5
6 - List of all Associated tags of a variable                               EXECUTE [spBF_GetPlantModelByAsset] null, 6
7 - List of all Associated tags of a unit                                   EXECUTE [spBF_GetPlantModelByAsset] null, 7
8 - List of all Associated tags of a group                                  EXECUTE [spBF_GetPlantModelByAsset] null, 8
*/

CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetPlantModelByAsset] 
	@AssetId            int = 1
	,@AssetType         int = 3
       
AS 
		SET NOCOUNT ON
       
		DECLARE @NoOfRow int
       
		DECLARE @Assets TABLE (
			RowNumber int identity
			,AssetType int
			,AssetId int
			,AssetName nVARCHAR(100)
			,Identifier nVARCHAR(100)
			,IsOpenable bit
			,HasChildren bit
		)

BEGIN
		IF @AssetType = 1 -- all Areas(Departments)
		BEGIN
			IF EXISTS(SELECT 1 FROM dbo.Departments_Base WITH(NOLOCK) WHERE Dept_Id > 0)
			BEGIN
				INSERT INTO @Assets(AssetType, AssetId, AssetName, IsOpenable, HasChildren)
				SELECT AssetType = @AssetType
					,AssetId =  department.Dept_Id
					,AssetName = department.Dept_Desc
					,IsOpenable = 0
					,HasChildren = CASE WHEN (SELECT COUNT(*) FROM dbo.Prod_Lines_Base WITH(NOLOCK) WHERE Dept_Id = Department.Dept_Id) > 0 THEN 1 ELSE 0 END
				FROM dbo.Departments_Base Department WITH(NOLOCK) 
				WHERE Department.Dept_Id > 0
                           
				SELECT * FROM @Assets 
			END
			ELSE
				BEGIN
					SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
				RETURN
			END
		END
              
		ELSE IF @AssetType = 2 -- List of all lines of a particular department
		BEGIN
			IF @AssetId IS NULL -- List all the lines in the plant
			BEGIN
				INSERT INTO @Assets(AssetType, AssetId, AssetName, IsOpenable, HasChildren)
				SELECT AssetType = @AssetType
					,AssetId = Line.PL_Id
					,AssetName = Line.PL_Desc
					,IsOpenable = 1
					,HasChildren = CASE WHEN (SELECT COUNT(*) FROM dbo.Prod_Units_Base WITH(NOLOCK) WHERE PL_Id = Line.PL_Id) > 0 THEN 1 ELSE 0 END
				FROM  dbo.Prod_Lines_Base Line WITH(NOLOCK)
				WHERE Line.PL_Id > 0
				SELECT * FROM @Assets       
			END
            ELSE IF EXISTS (SELECT 1 FROM dbo.Prod_Lines_Base WITH(NOLOCK) WHERE Dept_Id = @AssetId AND PL_Id > 0) -- List of all lines of a particular department
            BEGIN
                INSERT INTO @Assets(AssetType, AssetId, AssetName, IsOpenable, HasChildren)
                SELECT AssetType = @AssetType
                    ,AssetId = Line.PL_Id
                    ,AssetName = Line.PL_Desc
                    ,IsOpenable = 1
                    ,HasChildren = CASE WHEN (SELECT COUNT(*) FROM dbo.Prod_Units_Base WITH(NOLOCK) WHERE PL_Id = Line.PL_Id) > 0 THEN 1 ELSE 0 END
                FROM  dbo.Prod_Lines_Base Line WITH(NOLOCK)     
                WHERE Line.PL_Id > 0
                AND Dept_Id = @AssetId
                     
                SELECT * FROM @Assets 
            END
            ELSE
            BEGIN
                SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            END
       END

       ELSE IF @AssetType = 3 -- List of all units of a particular line
       BEGIN
            IF EXISTS ( SELECT 1 FROM dbo.Prod_Units_Base WITH(NOLOCK) WHERE PL_Id = @AssetId AND PU_Id > 0)
            BEGIN
                INSERT INTO @Assets(AssetType, AssetId, AssetName, IsOpenable, HasChildren)
                SELECT AssetType = @AssetType
                    ,AssetId = Unit.PU_Id
                    ,AssetName = Unit.PU_Desc
                    ,IsOpenable = 1
                    ,HasChildren = CASE WHEN (SELECT COUNT(*) FROM dbo.PU_Groups WITH(NOLOCK) WHERE PU_Id = Unit.PU_Id) > 0 THEN 1 ELSE 0 END
                FROM dbo.Prod_Units_Base Unit WITH(NOLOCK)      
                WHERE Unit.PU_Id > 0
                AND Unit.PL_Id = @AssetId
                SELECT * FROM @Assets
            END
            ELSE
            BEGIN
                SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            END
       END

       ELSE IF @AssetType = 4 -- List of all Group of a particular unit
       BEGIN
            IF EXISTS ( SELECT 1 FROM dbo.PU_Groups WITH(NOLOCK) WHERE PU_Id = @AssetId AND PUG_Id > 0)
            BEGIN
                INSERT INTO @Assets(AssetType, AssetId, AssetName, IsOpenable, HasChildren)
                SELECT AssetType = @AssetType
					,AssetId = Groups.PUG_Id
					,AssetName = Groups.PUG_Desc
					,IsOpenable = 1
					,HasChildren = CASE WHEN (SELECT COUNT(*) FROM dbo.Variables WITH(NOLOCK) WHERE PUG_Id = Groups.PUG_Id) > 0 THEN 1 ELSE 0 END
                FROM  dbo.PU_Groups Groups WITH(NOLOCK)
                WHERE Groups.PUG_Id > 0
                AND Groups.PU_Id = @AssetId
				SELECT * FROM @Assets 
            END
            ELSE
            BEGIN
                SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            END
       END

       ELSE IF @AssetType = 5 -- List of all variable of a particular group
       BEGIN
            IF EXISTS (SELECT 1 FROM dbo.Variables WITH(NOLOCK) WHERE PUG_Id = @AssetId AND Var_id > 0)
            BEGIN
                INSERT INTO @Assets(AssetType, AssetId, AssetName, IsOpenable, HasChildren)
                SELECT AssetType = @AssetType
                        ,AssetId = V.Var_id
                        ,AssetName = V.Var_Desc
                        ,IsOpenable = 0
                        ,HasChildren = CASE WHEN V.Input_Tag IS NOT NULL THEN 1 ELSE 0 END
                FROM  dbo.Variables V WITH(NOLOCK)
                WHERE V.Var_id > 0
                AND V.PUG_Id = @AssetId
                SELECT * FROM @Assets 
            END
            ELSE
            BEGIN
                SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            END
       END

       ELSE IF @AssetType = 6 -- Associated tag of a variable
       BEGIN
            INSERT INTO @Assets(AssetType, AssetId, AssetName)
                SELECT AssetType = @AssetType
                ,AssetId = V.Var_id
                ,AssetName = V.Input_Tag                         
            FROM  Variables V WITH(NOLOCK)
            WHERE V.Var_Id= @AssetId 
            AND V.Input_Tag IS NOT NULL

            SELECT @NoOfRow = MAX(RowNumber) FROM @Assets 
            IF(@NoOfRow > 0 )
            BEGIN
                SELECT * FROM @Assets 
            END
            ELSE
            BEGIN
                SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            END
       END

       ELSE IF @AssetType = 7 -- Associated tag of a unit
       BEGIN
            INSERT INTO @Assets(AssetType, AssetId, AssetName)
                SELECT AssetType = @AssetType
                ,AssetId = V.Var_id
                ,AssetName = V.Input_Tag                         
            FROM  Variables V WITH(NOLOCK)
            WHERE V.PU_Id= @AssetId
            AND V.Input_Tag IS NOT NULL

            SELECT @NoOfRow = MAX(RowNumber) FROM @Assets
            IF(@NoOfRow > 0 )
            BEGIN
                SELECT * FROM @Assets 
            END
            ELSE
            BEGIN
                SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            END
       END

       ELSE IF @AssetType = 8 -- Associated tag of a group
       BEGIN
            INSERT INTO @Assets(AssetType, AssetId, AssetName)
                SELECT AssetType = @AssetType
                ,AssetId = V.Var_id
                ,AssetName = V.Input_Tag                         
            FROM  Variables V WITH(NOLOCK)
            WHERE V.PUG_Id= @AssetId
            AND V.Input_Tag IS NOT NULL

            SELECT @NoOfRow = MAX(RowNumber) FROM @Assets 
            IF(@NoOfRow > 0 )
            BEGIN
                SELECT * FROM @Assets 
            END
            ELSE
            BEGIN
                    SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            END
		END
END

GRANT  EXECUTE  ON [dbo].[spMesData_ProcAnz_GetPlantModelByAsset]  TO [ComXClient]
