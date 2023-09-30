CREATE FUNCTION [dbo].[fnCMN_ActivitiesCompleteTests](@ActivityId Int,@SheetId Int,@Title nVarChar(255),@UseTitles int) 
     RETURNS @TestCounts Table (TotalTests Int, CompleteTests Int, HasAvailableCells BIT)
AS 
BEGIN
   	   DECLARE @ResultOn DateTime
   	   DECLARE @SheetDesc nVarChar(100)
   	   DECLARE @TitleOrderStart Int
   	   DECLARE @TitleOrderEnd Int
   	   DECLARE @ActivityTypeId Int
 	   DECLARE @HasAvailableCells BIT
   	   DECLARE @PUId Int
   	   DECLARE @ProdId Int
   	   DECLARE @KeyId1 Int
   	   DECLARE  @End Int
   	   DECLARE  @Sheets TABLE(Id Int Identity (1,1), Sheet_Id int, HasActivities int, TitleActivities int, Sheet_Desc nVarchar(255))
   	   DECLARE  @DeletedIds TABLE(Id Int Identity (1,1), ActivityId int, KeyId int, StartTime DateTime, ActivityType Int,PUId Int)
    	    DECLARE  @variables TABLE(varId Int,VarOrder Int,Title nvarchar(255), HasValue int, SheetId int,IsMandatory int)
   	   DECLARE  @titlesTable TABLE(title nvarchar(255), startId int, endId int, SheetId int)
 	   DECLARE @AvailableVariables TABLE (Var_Id INT)
   	   IF @ActivityId Is Not Null
   	   BEGIN
   	      	   SELECT @SheetId = Sheet_id,
   	      	      	      	   @ResultOn = KeyId,
   	      	      	      	   @Title = Title,
   	      	      	      	   @ActivityTypeId = Activity_Type_Id,
   	      	      	      	   @KeyId1 = KeyId1,
 	  	  	  	   @PUId = PU_Id
   	      	      	   FROM Activities (nolock)
   	      	      	   WHERE Activity_Id = @ActivityId
   	      	   If(@ActivityTypeId = 2) --Production Events
   	      	   BEGIN
   	      	      	   --Retrieve Time Stamp
   	      	      	   SELECT @ResultOn = [TimeStamp]
   	      	      	   FROM Events (nolock)
   	      	      	   WHERE Event_Id = @KeyId1
   	      	   END
 	  	   SELECT @ProdId = Prod_Id FROM Production_Starts WHERE PU_Id = @PUId
                                                      AND Start_Time <= @ResultOn
                                                      AND (End_Time IS NULL
                                                           OR End_Time > @ResultOn)
   	   
   	      	   SELECT @UseTitles = Value FROM Sheet_Display_Options (nolock) WHERE Sheet_Id = @SheetId And Display_Option_Id = 445
   	      	   SELECT @UseTitles = Coalesce(@UseTitles,0)
    	        	    IF @UseTitles = 0
    	        	    BEGIN
  	    	    	   --INSERT INTO @AvailableVariables (Var_Id)
  	    	    	   -- 	  SELECT VB.Var_Id
  	    	    	   --   FROM Sheet_Variables AS SV
  	    	    	   -- 	      JOIN Variables_Base AS VB(NOLOCK) ON VB.Var_Id = SV.Var_Id
  	    	    	   -- 	      LEFT JOIN Var_Specs AS VS(NOLOCK) ON VB.Var_Id = VS.Var_Id
  	    	    	   -- 	    	    	    	    	    	    	    	    	   AND VS.Prod_Id = @ProdId
  	    	    	   -- 	    	    	    	    	    	    	    	    	   AND Effective_Date <= @ResultOn
  	    	    	   -- 	    	    	    	    	    	    	    	    	   AND (Expiration_Date IS NULL
  	    	    	   -- 	    	    	    	    	    	    	    	    	    	   OR Expiration_Date > @ResultOn)
  	    	    	   --   WHERE SV.Sheet_Id = @SheetId
  	    	    	   -- 	    	  AND VB.DS_Id = 2
  	    	    	   -- 	    	  AND (ISNULL(VB.Sampling_Interval, 0) > 0
  	    	    	   -- 	    	    	  OR ISNULL(VS.Test_Freq, 0) > 0)
  	    	    	      Insert Into @variables(varId, IsMandatory)
 	  	  	  	  	 Select Var_Id,0 from Sheet_variables where Sheet_id =@SheetId
 	  	  	  	  	 
 	  	  	  	  	 UPDATE V SET  	 IsMandatory 	  	 = isnull(t.IsVarMandatory,0)
 	  	  	  	  	 from @variables   V  
 	  	  	  	  	  Join Tests  t On t.var_id = V.varid and t.Result_On = @ResultOn
  	    	    	    	  
    	        	        	    INSERT INTO @TestCounts(TotalTests,CompleteTests,HasAvailableCells)
    	        	        	        	    SELECT Count(1), SUM(CASE 
  	    	    	    	    	    	    	    	    	    	    	    	    	    	  WHEN (CASE WHEN v.Data_Type_Id >50 Then 1 ELSE v.Data_Type_Id END in (1,2,3,4,6,7) AND t.Result is null) THEN 0 
  	    	    	    	    	    	    	    	    	    	    	    	    	    	  WHEN (v.Data_Type_Id = 5 AND t.Comment_Id is null) THEN 0 --added to count comment type as well 
  	    	    	    	    	    	    	    	    	    	    	    	    	    	  ELSE 1 END),
  	    	    	    	    	    	    	  Case when exists (select 1 from @variables where IsMandatory = 1 ) Then 1 else 0 End
    	        	        	        	    FROM Sheet_Variables sv (nolock)
    	        	        	        	    JOIN Variables_Base v (nolock) on v.Var_Id = sv.Var_Id
    	        	        	        	    LEFT JOIN @Variables AV ON AV.varId = SV.Var_Id
    	        	        	        	    LEFT JOIN Tests t (nolock) on t.Var_Id = sv.Var_Id and t.Result_On = @ResultOn 
  	    	    	    	    	    	    	    
    	        	        	        	     WHERE CASE WHEN v.Data_Type_Id >50 Then 1 ELSE v.Data_Type_Id END IN (1,2,3,4,5,6,7)  AND v.DS_Id in ( 2,16 ) and sv.Sheet_Id =  @SheetId 
  	    	    	    	  	  	  	  	 AND 
 	  	  	  	  	  	  	  	  	 (
 	  	  	  	  	  	  	  	  	  	 (EXISTS (Select 1 from @variables where IsMandatory = 1 AND varId = v.Var_Id) AND t.Test_Id IS NOT NULL)
 	  	  	  	  	  	  	  	  	  	 OR
 	  	  	  	  	  	  	  	  	  	 (NOT EXISTS (Select 1 from @variables where IsMandatory = 1))
 	  	  	  	  	  	  	  	  	 )  
 	  	  	  	    
    	        	    END
    	        	    ELSE
    	        	    BEGIN
    	        	        	    SELECT @SheetDesc = Sheet_Desc + '-' FROM Sheets (nolock) WHERE Sheet_Id = @SheetId
    	        	        	    SET @Title = Replace(@Title,@SheetDesc,'')
    	        	        	    SELECT @TitleOrderStart = Var_Order From Sheet_Variables (nolock)  WHERE Sheet_id = @SheetId and Title = @Title
  	    	    	    	    	    SET @TitleOrderStart = ISNULL(@TitleOrderStart, 0)
  	    	    	     
  	    	    	    	 
 	  	  	  	  	 Insert Into @variables(varId, IsMandatory)
 	  	  	  	  	 Select Var_Id,0 from Sheet_variables where Sheet_id =@SheetId
 	  	  	  	  	 
 	  	  	  	  	 UPDATE V SET  	 IsMandatory 	  	 = isnull(t.IsVarMandatory,0)
 	  	  	  	  	 from @variables   V  
 	  	  	  	  	  Join Tests  t On t.var_id = V.varid and t.Result_On = @ResultOn
  	    	    	    	  
    	        	        	    INSERT INTO @TestCounts(TotalTests,CompleteTests,HasAvailableCells)
    	        	        	        	    SELECT Count(1), SUM(CASE 
  	    	    	    	    	    	    	    	    	    	    	    	    	    	  WHEN (CASE WHEN v.Data_Type_Id >50 Then 1 ELSE v.Data_Type_Id END in (1,2,3,4,6,7) AND t.Result is null) THEN 0 
  	    	    	    	    	    	    	    	    	    	    	    	    	    	  WHEN (v.Data_Type_Id = 5 AND t.Comment_Id is null) THEN 0 --added to count comment type as well 
  	    	    	    	    	    	    	    	    	    	    	    	    	    	  ELSE 1 END),
  	    	    	    	    	    	    	   Case when exists (select 1 from @variables where IsMandatory = 1 ) Then 1 else 0 End
    	        	        	        	    FROM Sheet_Variables sv (nolock)
    	        	        	        	    JOIN Variables_Base v (nolock) on v.Var_Id = sv.Var_Id
    	        	        	        	    LEFT JOIN @AvailableVariables AV ON AV.Var_Id = SV.Var_Id
    	        	        	        	    LEFT JOIN Tests t (nolock) on t.Var_Id = sv.Var_Id and t.Result_On = @ResultOn 
  	    	    	    	    	    	    	    WHERE CASE WHEN v.Data_Type_Id >50 Then 1 ELSE v.Data_Type_Id END IN (1,2,3,4,5,6,7)  AND v.DS_Id in ( 2,16)  and sv.Sheet_Id =  @SheetId and (sv.Title_Var_Order_Id = @TitleOrderStart)
  	    	    	    	      AND 
 	  	  	  	  	  	  	  	  	 (
 	  	  	  	  	  	  	  	  	  	 (EXISTS (Select 1 from @variables where IsMandatory = 1 AND varId = v.Var_Id) AND t.Test_Id IS NOT NULL)
 	  	  	  	  	  	  	  	  	  	 OR
 	  	  	  	  	  	  	  	  	  	 (NOT EXISTS (Select 1 from @variables where IsMandatory = 1))
 	  	  	  	  	  	  	  	  	 )
    	        	    END
   	   END
   	   ELSE
   	   BEGIN
   	      	   IF @UseTitles = 0 
   	      	   BEGIN
   	      	      	   INSERT INTO @TestCounts(TotalTests,CompleteTests,HasAvailableCells)
   	      	      	      	   SELECT Count(1), 0, NULL
   	      	      	      	   FROM Sheet_Variables sv (nolock)
   	      	      	      	   JOIN Variables_Base v (nolock) on v.Var_Id = sv.Var_Id
   	      	      	      	   WHERE CASE WHEN v.Data_Type_Id >50 Then 1 ELSE v.Data_Type_Id END IN (1,2,3,4,5,6,7)  AND v.DS_Id in ( 2,16)  and sv.Sheet_Id =  @SheetId
   	      	   END
   	      	   ELSE
   	      	   BEGIN
   	      	      	   SELECT @TitleOrderStart = Var_Order From Sheet_Variables  WHERE Sheet_id = @SheetId and Title = @Title
   	      	      	   INSERT INTO @TestCounts(TotalTests,CompleteTests,HasAvailableCells)
   	      	      	      	   SELECT Count(1), 0, NULL
   	      	      	      	   FROM Sheet_Variables sv (nolock)
   	      	      	      	   JOIN Variables_Base v (nolock) on v.Var_Id = sv.Var_Id
   	      	      	      	   WHERE 
 	  	  	  	  	  	  	   --(v.Data_Type_Id in (1,2,3,4,5) OR v.Data_Type_Id > 50)  
 	  	  	  	  	  	  	   
 	  	  	  	  	  	  	   CASE WHEN v.Data_Type_Id >50 Then 1 ELSE v.Data_Type_Id END IN (1,2,3,4,5,6,7)
 	  	  	  	  	  	  	   
 	  	  	  	  	  	  	   AND v.DS_Id in ( 2,16)  and sv.Sheet_Id =  @SheetId and (sv.Title_Var_Order_Id = @TitleOrderStart)
   	      	   END
   	   END
   	   UPDATE @TestCounts set TotalTests = 0 WHERE TotalTests Is Null
   	   UPDATE @TestCounts set CompleteTests = 0 WHERE CompleteTests Is Null
 	   IF EXISTS (SELECT 1 FROM @TestCounts where TotalTests = 0 ) 
 	   BEGIN
 	  	 set @HasAvailableCells = 0
 	  	 UPDATE @TestCounts SET HasAvailableCells = 0 WHERE TotalTests = 0
 	   END
   	   RETURN
END
