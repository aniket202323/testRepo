CREATE PROCEDURE dbo.spXLAEventData_Expand
 	   @Var_Id 	 Int
 	 , @PU_Id 	 Int
 	 , @EventNum  	 varchar(20)
 	 , @EventId 	 Int = Null
 	 , @DecimalSep 	 varchar(1) = NULL 	 --MT/4-10-2002
 	 , @InTimeZone 	 varchar(200) = null
AS
DECLARE @MasterUnit  	 Int
DECLARE @DataType 	 Int
If @DecimalSep Is NULL SELECT @DecimalSep = '.'
SELECT @DataType   = Data_Type_Id FROM Variables WHERE Var_Id = @Var_Id
SELECT @MasterUnit = Master_Unit FROM Prod_Units WHERE PU_Id = @PU_Id
If @MasterUnit Is NULL  SELECT @MasterUnit = @PU_Id
If @EventNum Is Null SELECT @EventNum = Event_Num FROM Events WHERE Event_Id = @EventId    
--Retrieve data...
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT  [Result_On] =  t.Result_On at time zone @DBTz at time zone @InTimeZone
 	   , [Entry_On] =  t.Entry_On at time zone @DBTz at time zone @InTimeZone
      , [Result] = Case When @DecimalSep <> '.' and @DataType = 2 Then REPLACE(t.Result, '.', @DecimalSep) Else t.Result End
--    , t.Result
      , t.canceled, t.Comment_Id, p.Prod_Code, s.ProdStatus_Desc as 'Event_Status'
  FROM 	  Events e
  LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status 
  LEFT OUTER JOIN Tests t ON t.result_on = e.timestamp AND t.var_id = @Var_Id, Production_Starts ps
  JOIN  Products p ON p.Prod_Id = ps.Prod_Id
 WHERE 	 (e.PU_Id = @MasterUnit) 
   AND 	 (e.Event_Num = @EventNum) 
   AND 	 (ps.PU_Id = @MasterUnit) 
   AND 	 (ps.Start_Time <= e.TimeStamp AND (ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL))
 	  	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
