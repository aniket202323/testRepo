
Create Procedure [dbo].[spActivities_GetVariableSpecs]
@VarIds nVarChar(max),
@StartTime DateTime

AS

DECLARE @PU_Id Int, @Prod_Id Int,@Prod_Code nvarchar(100), @Start_Id Int, @End Int, @Start Int, @ProductStartTime DateTime
DECLARE @AllVars Table (VarId Int, ProdId Int, PUId Int, ProductStartTime DateTime,
SA_Id tinyint, Sampling_Interval int, Data_Type_Id int, esignatureLevel int

)
DECLARE @AllUnits Table (Id Int Identity (1,1), PUId Int)

--Convert time from UTC to DBTime
;WITH TZ(StartTime,
               EndTime,
               Bias)
            AS (
            SELECT StartTime,
                   EndTime,
                   UTCbias FROM TimeZoneTranslations WHERE TimeZone = (SELECT TOP 1 Value FROM site_parameters WHERE parm_id = 192))
SELECT @StartTime = DATEADD(MINUTE, (SELECT TOP 1 Bias FROM TZ WHERE @StartTime >= StartTime
                                                                    AND @StartTime < EndTime)*-1, @StartTime)
--Split comma seperated string
DECLARE @xml XML
SET @xml = cast(('<X>'+replace(@VarIds,',','</X><X>')+'</X>') as xml)
INSERT INTO @AllVars(VarId)
SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)

--Get units for Variables
UPDATE av
SET av.PUId = Coalesce(p.Master_Unit,p.PU_Id)
,av.SA_Id = v.SA_Id, av.Sampling_Interval = v.Sampling_Interval, av.Data_Type_Id = v.Data_Type_Id, av.esignatureLevel = v.Esignature_Level
FROM Variables_Base v
JOIN @AllVars av on av.VarId = v.Var_Id
JOIN Prod_Units p on p.PU_Id = v.PU_Id 
 
 --Get distinct units to loop through
 INSERT INTO @AllUnits(PUId)
 SELECT DISTINCT PUID from @AllVars

--Loop through Units to get Products and update VarTable
SET @Start = 1
SELECT @End = Max(Id) From @AllUnits 
WHILE @Start <= @End
BEGIN
	SELECT  @PU_Id = PUId
	FROM @AllUnits 
	WHERE Id = @Start

	--Retrieve Product Id
	EXECUTE spActivities_GetRunningGrade @PU_Id,@StartTime,1, @Prod_Id OUTPUT, @Prod_Code OUTPUT ,@Start_Id OUTPUT, @ProductStartTime OUTPUT

	UPDATE @AllVars
	SET ProdId = @Prod_Id,
		ProductStartTime = CASE WHEN @ProductStartTime IS NULL THEN @StartTime ELSE @ProductStartTime END
	WHERE PUId = @PU_Id

	SET @Start = @Start + 1
END

 

Select VariableId = av.VarId,
         s.U_Entry,
         s.L_Entry,
         s.U_Reject,
         s.L_Reject,
         s.U_Warning,
         s.L_Warning,
         s.U_User,
         s.L_User,
         s.U_Control,
         s.L_Control,
         s.Target,
         s.T_Control,
		 CASE 
			WHEN s.esignature_level IS NULL
			THEN av.esignatureLevel ELSE s.esignature_level
		 END AS esignatureLevel,
		 	 
         CASE 
			WHEN av.Sampling_Interval IS NULL OR av.Sampling_Interval = 0 
			THEN s.Test_Freq ELSE av.Sampling_Interval
		 END AS Test_Freq,
		 av.Data_Type_Id
  FROM @AllVars av 
  --JOIN Variables v ON v.Var_Id = av.VarId 
  LEFT JOIN var_specs s ON av.VarId = s.Var_Id AND av.ProdId = s.Prod_Id
   
	AND 
	(
		(
			ISNULL(av.SA_Id,1) <> 2 AND
			s.effective_date <= @StartTime AND
			(
				(s.expiration_date > @StartTime) OR (s.expiration_date IS NULL)
			)
		)
		OR 
		(
			av.SA_Id = 2 AND
			s.effective_date <= av.ProductStartTime AND
			(
				(s.expiration_date > av.ProductStartTime) OR (s.expiration_date IS NULL)
			)
		)
	)
ORDER BY VariableId

