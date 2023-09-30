

--================================================================================================
--Stored Procedure		:	splocal_PG_NextActivities_GetSheets
--Author				:	Steven Stier , Stier Automation LLC
--Date Created			:	2020-01-14
--Called By				:	Next Activities Estimate API
--Editor Tab Spacing	:	2
--================================================================================================
--Purpose:
--------------------------------------------------------------------------------------------------
-- This SP will get all Sheets to monitor for the Next Activites Estimate Core service
--================================================================================================
--Input Parameters:
--------------------------------------------------------------------------------------------------
--Input#	Input Name				Input Type			Description
---------	-------------------		----------			------------------------------------------
--	1		@PUIds					String				comma seperated List of PUids to filter by
--================================================================================================
-- Edit History:
-------------------------------------------------------------------------------------------------
--Revision	Date			Who						What
--========	===========		=====================	==============================================
-- 0.1		2021-01-14		Steven Stier			Creation of the Stored Procedure 
-- 0.2		2021-02-07		Steven Stier			new SP name splocal_PG_NextActivities_GetSheets
-- 0.3		2021-02-12		Steven Stier			Added @PUIds inputs
-- 0.4		2021-03-30		Steven Stier			Refactoring after Review with the venerable M Benchia
-- 0.5		2021-03-31		Steven Stier			Added Event_Subtype_Desc 
-- 0.6		2021-04-02		Steven Stier			Added Returns instead of Finished.
-- 0.7		2021-06-18		Steven Stier			Added 60 seconds to duration to account for Model 
-- 0.8		2021-07-08		Steven Stier			Updated Test units 
-- 0.9		2021-08-20		Steven Stier			Removed the 60 secs from above after V8_2
-- 0.10		2021-11-11		Steven Stier			Added NAE User to permissions
-- 0.11		2021-12-18		Steven Stier			Added no lock to select from sheets
-- 0.12		2022-03-23		Steven Stier			Added Red and Yellow limits from Sheets display options
-- 0.13		2022-05-13		Steven Stier			Testing on Development Server
-- 0.14   2022-09-15    Steven Stier      fixed issue with getting activites with incorrect event models
-- 0.15   2022-11-09    Steven Stier      fixed issue where configuratons allow multiple subtypes with same name within a production unit. picking top 1 by priority
-- 0.16   2022-11-23    Steven Stier      Added Option to get ALL sheets
--
--================================================================================================
--TESTING
--------------------------------------------------------------------------------------------------
/*
Exec splocal_PG_NextActivities_GetSheets  "2" --SA Dev System (no sheets)
Exec splocal_PG_NextActivities_GetSheets  "3" --SA Dev System (sheet every 30 mins and hour- 2 sheets)
Exec splocal_PG_NextActivities_GetSheets  "2,3" --SA Dev System (still just 2)
Exec splocal_PG_NextActivities_GetSheets  "5" --SA Dev System (2 sheets) 
Exec splocal_PG_NextActivities_GetSheets  "3,8" --SA Dev System ( 4 sheets)
Exec splocal_PG_NextActivities_GetSheets  "609,610" --Funct BOX (should return 4 if NAE Test units configured and active)
Exec splocal_PG_NextActivities_GetSheets  "8705,8706" --Funct BOX (should return 4 if NAE Test units configured and active)
Exec splocal_PG_NextActivities_GetSheets  "44,45,46,47,48,49,50,51,387,465" -- Amiens prod
Exec splocal_PG_NextActivities_GetSheets  "148"-- Failed prior to 0.15 in ameins prod
Exec splocal_PG_NextActivities_GetSheets  "ALL"  -- test for 0.16 changes
*/
--------------------------------------------------------------------------------------------------
--================================================================================================
Create  PROCEDURE [dbo].[splocal_PG_NextActivities_GetSheets]
          @PUIds     nVARCHAR(max),
					@Error_Message nVARCHAR(400) = '' Output
--WITH ENCRYPTION  
AS
SET NOCOUNT ON  
BEGIN
DECLARE		@ED_FIELD_ID	int,
			@Yellow_Limit_Display_ID int,
			@Red_Limit_Display_ID int

	SELECT @Error_Message = '';

	IF (@PUids is NULL or @PUIds = '' or len(@Puids) = 0)
		BEGIN
				SET @Error_Message = 'PUids Null or Blank'
				RETURN;
		END;

	--------------------------------------------------------------------------------------------------
	--get the comma seperate PUIDs and populate @Units
	--------------------------------------------------------------------------------------------------
	DECLARE @Units TABLE(UnitId INT NULL)
	--------------------------------------------------------------------------------------------------
  -- get all the production units on the whole server if asked - 11/23/2022
  -------------------------------------------------------------------------------------------------
  IF (UPPER(@PUIds) = 'ALL')
    BEGIN
      INSERT INTO @Units (UnitID) SELECT PU_Id FROM Prod_Units_Base  with(nolock) ;
    END;
  ELSE
    BEGIN
      BEGIN TRY
		    INSERT INTO @Units (UnitID) SELECT value FROM STRING_SPLIT( @PUIds,',') WHERE value <> '';
	    END TRY
	    BEGIN CATCH
		    SET @Error_Message = 'Cannot Parse String'
		    RETURN;
	    END CATCH
    END
	

	
	--------------------------------------------------------------------------------------------------
	-- Initialize the temp tables
	--------------------------------------------------------------------------------------------------
	-- #Results = holds all the sheets that will be monitored
	--------------------------------------------------------------------------------------------------
    CREATE TABLE #Results(Sheet_Id   INT,
							Sheet_Desc nVarchar(50),
							Sheet_Type INT,
							Event_Subtype_Id INT,
							Event_Subtype_Desc nVarChar(50),
                            Unit_id    INT,
                            Equipment  nVARCHAR(100),
							Ec_id INT,
							Ec_Desc nVARCHAR(50),
							Duration INT,
							YellowLimit INT,
							RedLimit INT
							)
	
		-------------------------------------------------------------------------------------------
		-- get the sheets for the Autolog Time based displays (Sheet Type = 1)
		-------------------------------------------------------------------------------------------
			
		/** --Removed for Prototype (Enable to support AutoLog Time Based Display Activites)  S. Stier 02-12-2021	
		INSERT INTO #Results( Sheet_Id,
								Sheet_Type,
								Sheet_Desc,
								Unit_id
								)
		SELECT S.Sheet_Id,
				1,
				S.Sheet_Desc,
				SDO.Value AS Unit_Idf
				FROM Sheets AS S  with(nolock)
				---------------------------------------------------------------------------------
				-- Create Activites= True ==> Display_option_id=444 and value = 1 
				--  UnitforActivties = Display_option_id = 446 
				----------------------------------------------------------------------------------
				   
					JOIN Sheet_Display_Options AS SDO1 ON SDO1.Sheet_Id = S.Sheet_Id
															AND SDO1.Display_Option_Id = 444
															AND SDO1.Value = 1
					LEFT JOIN Sheet_Display_Options AS  SDO with(nolock) ON SDO.Sheet_Id = S.Sheet_Id
																AND SDO.Display_Option_Id = 446
					JOIN @Units AS U ON U.UnitId = SDO.Value
                                                       
				WHERE S.Sheet_Type = 1  AND S.Is_Active = 1
				  
			**/ --Removed for Prototype S. Stier 02-12-2021			

			-------------------------------------------------------------------------------------------
			-- gets all the sheets for the Autolog UDE Based Displays - (Sheet Type = 25)
			-------------------------------------------------------------------------------------------
			
			INSERT INTO #Results( Sheet_Id,
									Sheet_Type,
									Sheet_Desc,
									Event_Subtype_Id,
									Unit_id )
			SELECT S.Sheet_Id,
					25,
					S.Sheet_Desc,
					Event_Subtype_Id,
					S.Master_Unit AS Unit_Id
					FROM Sheets AS S  with(nolock)
					-------------------------------------------------------------------------------------
					-- Create activites option is enabled. 
					------Create Activites= True ==> Display_option_id=444 and value = 1 
					--- Sheet_type 25 = Autolog UDE displays
					----- Also determine if the UDP "EstimateActivity" is set on UDPs--> Event Subtypes
					--------------------------------------------------------------------------------------
						JOIN Sheet_Display_Options AS SDO  with(nolock) ON SDO.Sheet_Id = S.Sheet_Id
																AND SDO.Display_Option_Id = 444
																AND SDO.Value = 1
						JOIN @Units U  ON U.UnitId = S.Master_Unit 
					WHERE S.Sheet_type=25 AND S.Is_Active = 1
					AND S.Event_Subtype_Id IN ( SELECT keyid FROM Table_fields_values tfv with(nolock)
										JOIN Table_fields tf with(nolock) on tfv.Table_field_id = tf.Table_field_id
				  					WHERE (Table_field_desc = 'EstimateActivity')  AND  tfv.Value in ('1','Yes'))


			-- Get the Equipment Name - Production unit Name
			UPDATE #Results
				SET Equipment = (SELECT pu_desc FROM Prod_Units_Base  with(nolock) WHERE Pu_id = Unit_id)
			
			-- Get the Event SubType Desc
			UPDATE #Results
				SET Event_Subtype_Desc  = (SELECT Event_Subtype_Desc  FROM Event_Subtypes es with(nolock) 
							WHERE es.Event_Subtype_Id = #Results.Event_Subtype_Id)
			-----------------------------------------------------------------------------------------------------------------------
			-- Get the Duration (used for final calculation on estimated Activity Endtime)
			-----------------------------------------------------------------------------------------------------------------------
			-- Get the ECID
			UPDATE #Results
				SET Ec_id = (SELECT TOP 1 Ec_id FROM Event_Configuration ec  with(nolock) 
							WHERE ec.Event_Subtype_Id  = #Results.Event_Subtype_Id  
							AND ec.Pu_id = #Results.Unit_id Order by Priority ASC)
			UPDATE #Results
				SET EC_DESC = (SELECT EC_DESC FROM Event_Configuration ec  with(nolock) 
							WHERE ec.Ec_Id  = #Results.Ec_Id )
			-----------------------------------------------------------------------------------------

			
			Set @Yellow_Limit_Display_ID = (SELECT Display_option_ID
									FROM Display_Options WITH(NOLOCK)
									WHERE Display_Option_Desc = 'NAE Yellow Limit')

			UPDATE #Results
				SET YellowLimit = (SELECT value from  Sheet_Display_Options sdo with(nolock)
					where sdo.sheet_id = #Results.Sheet_Id and
						 sdo.Display_Option_Id = @Yellow_Limit_Display_ID)
			
			
			Set @Red_Limit_Display_ID = (SELECT Display_option_ID
									FROM Display_Options WITH(NOLOCK)
									WHERE Display_Option_Desc = 'NAE Red Limit')

			UPDATE #Results
				SET RedLimit = (SELECT value from  Sheet_Display_Options sdo with(nolock)
					where sdo.sheet_id = #Results.Sheet_Id and
						 sdo.Display_Option_Id = @Red_Limit_Display_ID)


			-----------------------------------------------------------------------------------------------------------------------
			--- For the UDE displays (sheet_type = 25) that are based on Uptime we  we need to get the duration by getting the 
			---  configuration from the Event configuration. In this Case it will be comming from  a specific Field in ED
			-- Note were using the unique Field_Desc = "TotalTime (In seconds)" which is a specfic field in all UDEs defined 
			-- using the standard UDE model "Q-Minutes of Run Time (Proficy Triggered)".
			-- get the Uptime Duration Frequency of the UDE model
			-----------------------------------------------------------------------------------------------------------------------
			Set @ED_FIELD_ID = (SELECT  ED_field_id from ed_fields  with(nolock) 
								where Field_desc = 'TotalTime (In seconds)')
	
	
			BEGIN TRY
				UPDATE #Results
				
					SET Duration = (select convert(int, (convert( varchar(max),value)))   
											FROM event_configuration_values ecv with(nolock) 
											JOIN event_configuration_data ecd with(nolock) on ecd.ecv_id = ecv.ecv_id
											WHERE ecd.ec_id = #Results.Ec_id and ED_Field_Id = @ED_FIELD_ID) WHERE Sheet_Type = 25
			END TRY

			BEGIN CATCH
				SET @Error_Message = 'Error In Set Duration.'
			END CATCH

			
			-----------------------------------------------------------------------------------------------------------------------
			-- For time based Activities use the configuration from the sheets to get the duration of the activity.
			-----------------------------------------------------------------------------------------------------------------------
			/** --Removed for Prototype--Needed for Support of Time Based Actvities S. Stier 02-12-2021	
			UPDATE #Results
				SET Duration = (SELECT (s.Interval * 60) FROM Sheets with(nolock) AS s where s.sheet_id = #Results.Sheet_Id) WHERE Sheet_Type = 1
			**/
      --- If we didnt find a duration dont include this for NAE 9/15/2022
      DELETE from #Results where Duration is NULL;

			IF(NOT EXISTS(SELECT 1 FROM #Results))
				BEGIN
					SET @Error_Message = 'No Sheets found.'
				END;

			---------------------------------------------------
			--- Return the results
			---------------------------------------------------
				
			SELECT Sheet_Id,
					Sheet_Desc,
					Sheet_type,
					Equipment,
					Unit_Id,
					Event_Subtype_Id,
					Event_Subtype_Desc,
					ec_id,
					Ec_Desc,
					Duration,
					YellowLimit,
					RedLimit
			FROM #Results ORDER BY Sheet_Desc

	DROP TABLE #Results

END
