 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-31  
Version  : 1.0.1  
Purpose  : Added [dbo] template when referencing objects.  
       
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Altered by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
*/  
CREATE procedure dbo.spLocal_FaultTimeByTime  
@OutputValue varchar(25) OUTPUT,  
@PU_ID int,  
@Start_Time datetime,  
@End_Time datetime,  
@Fault_Desc varchar(50)  
AS  
  
SET NOCOUNT ON  
  
DECLARE @Fault_Start_Time datetime  
DECLARE @Fault_End_Time datetime  
DECLARE @Fault_Time real  
DECLARE @Fault_ID INT  
  
SELECT @Fault_Desc = LTRIM(RTRIM(@Fault_Desc))  
SELECT @Fault_Time = 0.0  
  
  SELECT @Fault_ID = TEFault_ID FROM [DBO].Timed_Event_Fault WHERE TEFault_Name = @Fault_Desc   
  
  DECLARE Faults CURSOR FOR  
  SELECT Start_Time, End_Time  
  FROM [DBO].Timed_Event_Details  
  WHERE Pu_id = @PU_ID and TEFault_ID = @Fault_ID And   
              ((End_Time   > @Start_Time And End_Time   <= @End_Time) OR  
               (Start_Time >= @Start_Time And Start_Time < @End_Time) OR  
               (Start_Time <= @Start_Time And End_Time   >=  @End_Time) OR  
               (End_Time IS NULL))  
    
  OPEN Faults  
  
  FETCH NEXT FROM Faults INTO @Fault_Start_Time, @Fault_End_Time  
  WHILE @@FETCH_STATUS = 0  
  BEGIN  
      IF @Fault_Start_Time > @Start_Time  
      BEGIN  
          IF @Fault_End_Time <= @End_Time  
              SELECT @Fault_Time = @Fault_Time + convert(real,Datediff(s,@Fault_Start_Time,@Fault_End_Time))/60  
          ELSE  
              SELECT @Fault_Time = @Fault_Time + convert(real,Datediff(s,@Fault_Start_Time,@End_Time))/60  
      END  
      ELSE  
      BEGIN  
          IF @Fault_End_Time <= @End_Time   
              SELECT @Fault_Time = @Fault_Time + convert(real,Datediff(s,@Start_Time,@Fault_End_Time))/60  
          ELSE  
              SELECT @Fault_Time = @Fault_Time + convert(real,Datediff(s,@Start_Time,@End_Time))/60  
      END    
      FETCH NEXT FROM Faults INTO @Fault_Start_Time, @Fault_End_Time  
  END  
  CLOSE Faults  
  DEALLOCATE Faults  
  
  SELECT @OutputValue = Convert(varchar(25), IsNull(@Fault_Time,0.00))  
  
  
SET NOCOUNT OFF  
  
  
