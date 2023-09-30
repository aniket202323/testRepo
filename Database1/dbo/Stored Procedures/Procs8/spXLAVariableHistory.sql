CREATE Procedure dbo.spXLAVariableHistory
 	   @Var_Id 	 Integer
 	 , @Result_On 	 DateTime
 	 , @TimeOrder 	 TinyInt 	   = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Result_On = @Result_On at time zone @InTimeZone at time zone @DBTz 
If @TimeOrder = 0 	  	 -- Ascending Sort By "Entry On" Default
    BEGIN
 	 SELECT 
 	  	 h.Test_Id
 	  	 , [TimeStamp] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	 , h.Canceled
 	  	 , h.Result
 	  	 , [Entry_On] = h.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	 , h.Array_Id
 	  	 ,[EntryByUser] = u.Username
 	   FROM Test_History h 
 	   JOIN Tests t ON t.Test_Id = h.Test_Id AND t.Result_On = @Result_On AND t.Var_Id = @Var_Id
 	   JOIN Users u ON u.User_Id = h.Entry_By
        ORDER BY h.Entry_On ASC
    END
Else 	  	  	  	 -- Descending Sort By "Entry On"
    BEGIN
 	 SELECT 
 	  	 h.Test_Id
 	  	 , [TimeStamp] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	 , h.Canceled, h.Result
 	  	 , [Entry_On] = h.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	 , h.Array_Id
 	  	 , [EntryByUser] = u.Username 	 
 	   FROM Test_History h 
 	   JOIN Tests t ON t.Test_Id = h.Test_Id AND t.Result_On = @Result_On AND t.Var_Id = @Var_Id
 	   JOIN Users u ON u.User_Id = h.Entry_By
        ORDER BY h.Entry_On DESC
    END
--EndIf
