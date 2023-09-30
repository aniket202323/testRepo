-- ECR #26270 (mt/9-2-2003) Fix -- Added Canceled = 0 to be consistent with the rest of TestsData functionality in AddIn
--
CREATE PROCEDURE dbo.[spXLATestData_NoProduct_Bak_177]
 	   @Var_Id 	 Integer
 	 , @Start_Time 	 DateTime
 	 , @End_Time 	 DateTime
 	 , @Pu_Id 	 Integer
 	 , @TimeSort 	 SmallInt
 	 , @DecimalSep 	 varchar(1)= '.'
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
--JG Added this for regional settings:
--  Must replace the period in the result value with a comma if the 
--  passed decimal separator is not a period and the value is a float data type
If @DecimalSep is Null Set @DecimalSep = '.' 
DECLARE @DataType 	  	 Int
SELECT @DataType = Data_Type_Id FROM Variables WHERE Var_Id = @Var_Id
--JG END
DECLARE @QueryType 	  	 TinyInt
DECLARE @NoEndTimeAscending 	 TinyInt
DECLARE @NoEndTimeDescending 	 TinyInt
DECLARE @StartAndEndAscending 	 TinyInt
DECLARE @StartAndEndDescending 	 TinyInt
SELECT @NoEndTimeAscending  	 = 1
SELECT @NoEndTimeDescending  	 = 2
SELECT @StartAndEndAscending  	 = 3
SELECT @StartAndEndDescending  	 = 4
If @End_Time Is NULL AND @TimeSort = 1 	  	 SELECT @QueryType = @NoEndTimeAscending
Else If @End_Time Is NULL AND @TimeSort <> 1 	 SELECT @QueryType = @NoEndTimeDescending
Else If @TimeSort = 1 	  	  	  	 SELECT @QueryType = @StartAndEndAscending
Else 	  	  	  	  	  	 SELECT @QueryType = @StartAndEndDescending
-- Note: No EndTime corresponds to Proficy function call for TestsData At specific times. Don't filter by Canceled = 0 or 1
If @QueryType = @NoEndTimeAscending
    BEGIN
        SELECT  [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), t.Canceled, 
                  [Result] = CASE 
                                WHEN @DecimalSep <> '.' and @DataType = 2 THEN REPLACE(t.Result, '.', @DecimalSep)
                                ELSE t.Result
                              END,
                [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Comment_Id, e.Event_Id, e.Event_Num, ps.ProdStatus_Desc as 'Event_Status'
          FROM  Tests t 
          LEFT OUTER JOIN  Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          LEFT OUTER JOIN  Production_Status ps ON ps.ProdStatus_Id = e.Event_Id
         WHERE t.Var_Id = @Var_Id AND t.Result_on = @Start_Time /* AND t.Canceled = 0 -- added Canceled=0: ECR #26270 (mt/9-2-2003) */
      ORDER BY t.Result_On ASC
    END
Else If @QueryType = @NoEndTimeDescending
    BEGIN
        SELECT  [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), t.Canceled, 
                  [Result] = CASE 
                                WHEN @DecimalSep <> '.' and @DataType = 2 THEN REPLACE(t.Result, '.', @DecimalSep)
                                ELSE t.Result
                              END,
                [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Comment_Id, e.Event_Id, e.Event_Num, ps.ProdStatus_Desc as 'Event_Status'
          FROM  Tests t 
          LEFT OUTER JOIN  Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          LEFT OUTER JOIN  Production_Status ps ON ps.ProdStatus_Id = e.Event_Id
         WHERE t.Var_Id = @Var_Id AND t.Result_on = @Start_Time /* AND t.Canceled = 0 -- added Canceled=0: ECR #26270 (mt/9-2-2003) */
      ORDER BY t.Result_On DESC
    END
Else If @QueryType = @StartAndEndAscending
    BEGIN
        SELECT [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), t.Canceled, 
               [Result] = CASE 
                             WHEN @DecimalSep <> '.' and @DataType = 2 THEN REPLACE(t.Result, '.', @DecimalSep)
                             ELSE t.Result
                          END,
               [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Comment_Id, e.Event_Id, e.Event_Num, ps.ProdStatus_Desc as 'Event_Status'
          FROM Tests t 
 	   LEFT OUTER JOIN  Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
 	   LEFT OUTER JOIN  Production_Status ps ON ps.ProdStatus_Id = e.Event_Id
         WHERE t.Var_Id = @Var_Id AND t.Result_on >= @Start_Time AND t.Result_On <= @End_Time AND t.Canceled = 0 -- added Canceled=0: ECR #26270 (mt/9-2-2003)
      ORDER BY t.Result_On ASC
    END
Else if @QueryType = @StartAndEndDescending
    BEGIN
        SELECT [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), t.Canceled, 
               [Result] = CASE 
                            WHEN @DecimalSep <> '.' and @DataType = 2 THEN REPLACE(t.Result, '.', @DecimalSep)
                            ELSE t.Result
                          END,
               [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Comment_Id, e.Event_Id, e.Event_Num, ps.ProdStatus_Desc as 'Event_Status'
          FROM Tests t 
 	   LEFT OUTER JOIN  Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
 	   LEFT OUTER JOIN  Production_Status ps ON ps.ProdStatus_Id = e.Event_Id
         WHERE t.Var_Id = @Var_Id AND t.Result_on >= @Start_Time AND t.Result_On <= @End_Time AND t.Canceled = 0 -- added Canceled=0: ECR #26270 (mt/9-2-2003)
      ORDER BY t.Result_On DESC
    END
--EndIf
