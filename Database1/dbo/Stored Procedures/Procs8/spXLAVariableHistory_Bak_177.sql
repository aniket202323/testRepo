CREATE Procedure dbo.[spXLAVariableHistory_Bak_177]
 	   @Var_Id 	 Integer
 	 , @Result_On 	 DateTime
 	 , @TimeOrder 	 TinyInt 	   = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @Result_On = dbo.fnServer_CmnConvertToDBTime(@Result_On,@InTimeZone)
If @TimeOrder = 0 	  	 -- Ascending Sort By "Entry On" Default
    BEGIN
 	 SELECT 
 	  	 h.Test_Id
 	  	 , [TimeStamp] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	 , h.Canceled
 	  	 , h.Result
 	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(h.Entry_On,@InTimeZone)
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
 	  	 , [TimeStamp] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	 , h.Canceled, h.Result
 	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(h.Entry_On,@InTimeZone)
 	  	 , h.Array_Id
 	  	 , [EntryByUser] = u.Username 	 
 	   FROM Test_History h 
 	   JOIN Tests t ON t.Test_Id = h.Test_Id AND t.Result_On = @Result_On AND t.Var_Id = @Var_Id
 	   JOIN Users u ON u.User_Id = h.Entry_By
        ORDER BY h.Entry_On DESC
    END
--EndIf
