Create Procedure dbo.spXLAEventData
 	 @Var_Id 	 int,
 	 @PU_Id 	 int,
 	 @EventNum  	 varchar(20),
 	 @EventId 	 int = Null,
 	 @DecimalSep 	 varchar(1)= NULL 	 --MT/4-9-2002
 	 , @InTimeZone 	 varchar(200) = null
AS
DECLARE @MasterUnit  	 int
 	 --BEGIN:MT/4-9-2002
DECLARE @DataType 	 Int
If @DecimalSep Is NULL SELECT @DecimalSep = '.' 
SELECT @DataType = Data_Type_Id FROM Variables WHERE Var_Id = @Var_Id
 	 --END:
IF @PU_Id Is Null
 	 SELECT @PU_Id = Pu_Id From Variables WHERE Var_Id = @Var_Id
SELECT 	 @MasterUnit = Master_Unit
FROM 	 Prod_Units 
WHERE 	 PU_Id = @PU_Id
If @MasterUnit Is NULL 
    BEGIN      
 	 SELECT @MasterUnit = @PU_Id
    END  
If @EventNum Is Null
    BEGIN
 	 SELECT  @EventNum = Event_Num
 	 FROM 	   Events
 	 WHERE 	   Event_Id = @EventId    
    END
/*  -------------------------------
    Retrieve data...
    ------------------------------- */
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT  [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	   , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
     , [Result] = Case When @DecimalSep <> '.' AND @DataType = 2 Then REPLACE(t.Result, '.', @DecimalSep) Else t.Result End
     , T.canceled
     , T.Comment_Id
     , PS.prod_id
  FROM Events Ev WITH (index(Event_By_PU_And_Event_Number))
  LEFT OUTER JOIN Tests T ON (T.result_on = Ev.timestamp) 
   AND (T.var_id = @Var_Id), Production_Starts PS WITH(index(Production_Starts_By_PU_Start))
 WHERE (Ev.PU_Id = @MasterUnit) 
   AND (Ev.Event_Num = @EventNum) 
   AND (PS.PU_Id = @MasterUnit) AND (PS.Start_Time <= Ev.TimeStamp AND (PS.End_Time > Ev.TimeStamp OR PS.End_Time Is NULL))
 	  	  	            --Start_time & End_time condition checked ; MSi/MT/3-21-2001
