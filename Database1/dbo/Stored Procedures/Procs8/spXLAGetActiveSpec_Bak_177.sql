CREATE PROCEDURE dbo.[spXLAGetActiveSpec_Bak_177]
 	   @SpecID 	 integer
 	 , @CharId 	 integer
 	 , @STime 	 datetime 
 	 , @DecimalSep 	 varchar(1)= '.'
 	 , @InTimeZone 	 varchar(200) = null
AS
--JG Added this for regional settings:
--  Must replace the period in the result value with a comma if the 
--  passed decimal separator is not a period.
If @DecimalSep is Null Set @DecimalSep = '.' 
SELECT @STime = dbo.fnServer_CmnConvertToDBTime(@STime,@InTimeZone)
DECLARE @DataType 	  	 Int
SELECT @DataType = Data_Type_Id FROM Specifications WHERE Spec_Id = @SpecId
--JG END
-- Added Transaction Comment; MSi/mt/9-7-2001
If @DecimalSep = '.' and @DataType = 2 
  BEGIN 
             SELECT DISTINCT
                a.AS_Id 
               ,Effective_Date = dbo.fnServer_CmnConvertFromDbTime(a.Effective_Date,@InTimeZone)
               ,Expiration_Date = dbo.fnServer_CmnConvertFromDbTime(a.Expiration_Date,@InTimeZone)
               ,a.Test_Freq
               ,a.Defined_By
               ,a.Spec_Id
               ,a.Deviation_From
               ,a.Char_Id 
               ,a.Comment_Id
               ,a.Is_Defined
               ,a.Is_OverRidable
               ,a.Is_Deviation
               ,a.Is_L_Rejectable
               ,a.Is_U_Rejectable
               ,[L_Warning] 
               ,[L_Reject] 
               ,[L_Entry]  
               ,[U_User]   
               ,[Target]   
               ,[L_User]   
               ,[U_Entry]  
               ,[U_Reject] 
               ,[U_Warning]
               , Trans_Comment_Id = t.Comment_Id
               FROM Active_Specs a
 	  	  	  	 LEFT  JOIN Transactions t ON t.Effective_Date = a.Effective_Date
              WHERE a.Spec_Id = @SpecId 
                AND a.char_id = @CharId 
                AND a.Effective_Date <= @Stime 
                AND (a.Expiration_Date > @STime OR a.Expiration_Date IS NULL)
  END
ELSE
  BEGIN 
             SELECT DISTINCT
                a.AS_Id 
               ,Effective_Date = dbo.fnServer_CmnConvertFromDbTime(a.Effective_Date,@InTimeZone)
               ,Expiration_Date = dbo.fnServer_CmnConvertFromDbTime(a.Expiration_Date,@InTimeZone)
               ,a.Test_Freq
               ,a.Defined_By
               ,a.Spec_Id
               ,a.Deviation_From
               ,a.Char_Id 
               ,a.Comment_Id
               ,a.Is_Defined
               ,a.Is_OverRidable
               ,a.Is_Deviation
               ,a.Is_L_Rejectable
               ,a.Is_U_Rejectable
               ,[L_Warning] = REPLACE(a.L_Warning, '.', @DecimalSep)
               ,[L_Reject] = REPLACE(a.L_Reject, '.', @DecimalSep) 
               ,[L_Entry] = REPLACE(a.L_Entry, '.', @DecimalSep)  
               ,[U_User] = REPLACE(a.U_User, '.', @DecimalSep)   
               ,[Target] = REPLACE(a.Target, '.', @DecimalSep)   
               ,[L_User] = REPLACE(a.L_User, '.', @DecimalSep)   
               ,[U_Entry] = REPLACE(a.U_Entry, '.', @DecimalSep)  
               ,[U_Reject] = REPLACE(a.U_Reject, '.', @DecimalSep) 
               ,[U_Warning] = REPLACE(a.U_Warning, '.', @DecimalSep)
               , Trans_Comment_Id = t.Comment_Id 
               FROM Active_Specs a
    LEFT OUTER JOIN Transactions t ON t.Effective_Date = a.Effective_Date
              WHERE a.Spec_Id = @SpecId 
                AND a.char_id = @CharId 
                AND a.Effective_Date <= @Stime 
                AND (a.Expiration_Date > @STime OR a.Expiration_Date IS NULL)
  END
