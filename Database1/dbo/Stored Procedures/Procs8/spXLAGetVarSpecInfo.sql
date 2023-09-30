--  exec spXLA_VarSpecInfo 18,NULL,2,NULL,'2014-06-05 12:29:53','.','Central Standard Time'
--  spXLAGetVarSpecInfo 18,6,'05/01/2014','.','Central Standard Time'
Create Procedure dbo.spXLAGetVarSpecInfo
 	   @Var_Id 	 int
 	 , @Prod_Id 	 int
 	 , @STime 	 datetime 
 	 , @DecimalSep 	 varchar(1)= '.'
 	 ,@InTimeZone 	 varchar(200)=null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @STime = @STime at time zone @InTimeZone at time zone @DBTz 
--JG Added this for regional settings:
--  Must replace the period in the result value with a comma if the 
--  passed decimal separator is not a period.
If @DecimalSep is Null Set @DecimalSep = '.' 
DECLARE @DataType 	  	 Int
SELECT @DataType = Data_Type_Id FROM Variables WHERE Var_Id = @Var_Id
--JG END
-- Added Transaction Comment; MSi/mt/9-7-2001
If @DecimalSep = '.' and @DataType = 2 
  BEGIN 
             SELECT 
                v.VS_Id 
               ,Effective_Date = v.Effective_Date at time zone @DBTz at time zone @InTimeZone
               ,Expiration_Date = v.Expiration_Date at time zone @DBTz at time zone @InTimeZone
               ,v.Deviation_From
               ,v.First_Exception
               ,v.Test_Freq
               ,v.AS_Id
               ,v.Comment_Id
               ,v.Var_Id
               ,v.Prod_Id
               ,v.Is_OverRiden
               ,v.Is_Deviation
               ,v.Is_OverRidable
               ,v.Is_Defined
               ,v.Is_L_Rejectable
               ,v.Is_U_Rejectable
               ,[L_Warning] 
               ,[L_Reject] 
               ,[L_Entry]  
               ,[U_User]   
               ,[Target]   
               ,[L_User]   
               ,[U_Entry]  
               ,[U_Reject] 
               ,[U_Warning]
               , t.Comment_Id as "Trans_Comment_Id"
               FROM Var_Specs v WITH (index(Var_Specs_By_Var_Prod_Effect))
    LEFT OUTER JOIN Transactions t ON t.Effective_Date = v.Effective_Date
              WHERE v.Var_Id = @Var_Id
                AND v.Prod_Id = @Prod_Id
                AND v.Effective_Date <= @Stime
                AND (v.Expiration_Date > @STime OR v.Expiration_Date IS NULL)
  END
ELSE
  BEGIN 
             SELECT 
                v.VS_Id 
               ,Effective_Date= v.Effective_Date at time zone @DBTz at time zone @InTimeZone
               ,Expiration_Date =v.Expiration_Date at time zone @DBTz at time zone @InTimeZone
               ,v.Deviation_From
               ,v.First_Exception
               ,v.Test_Freq
               ,v.AS_Id
               ,v.Comment_Id
               ,v.Var_Id
               ,v.Prod_Id
               ,v.Is_OverRiden
               ,v.Is_Deviation
               ,v.Is_OverRidable
               ,v.Is_Defined
               ,v.Is_L_Rejectable
               ,v.Is_U_Rejectable
               ,[L_Warning] = REPLACE(v.L_Warning, '.', @DecimalSep)
               ,[L_Reject] = REPLACE(v.L_Reject, '.', @DecimalSep) 
               ,[L_Entry] = REPLACE(v.L_Entry, '.', @DecimalSep)  
               ,[U_User] = REPLACE(v.U_User, '.', @DecimalSep)   
               ,[Target] = REPLACE(v.Target, '.', @DecimalSep)   
               ,[L_User] = REPLACE(v.L_User, '.', @DecimalSep)   
               ,[U_Entry] = REPLACE(v.U_Entry, '.', @DecimalSep)  
               ,[U_Reject] = REPLACE(v.U_Reject, '.', @DecimalSep) 
               ,[U_Warning] = REPLACE(v.U_Warning, '.', @DecimalSep)
               , t.Comment_Id as "Trans_Comment_Id"
               FROM Var_Specs v WITH (index(Var_Specs_By_Var_Prod_Effect))
 	  	  	   LEFT OUTER JOIN Transactions t ON t.Effective_Date = v.Effective_Date
              WHERE v.Var_Id = @Var_Id
                AND v.Prod_Id = @Prod_Id
                AND v.Effective_Date <= @Stime
                AND (v.Expiration_Date > @STime OR v.Expiration_Date IS NULL)
  END
