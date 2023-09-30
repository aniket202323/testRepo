-- spXLA_ActiveSpecInfo() combines spXLAGetActiveSpec and related lookup SP into a single stored procedure. 
-- MT/6-10-2002: Changes include: accepting ID or Desc for both Specification and Characteristic.
-- ECR 31165: mt/8-18-2006 -- added fields target control limit, upper control limit, lower control limit
CREATE PROCEDURE dbo.spXLA_ActiveSpecInfo
 	   @Spec_Id 	 Integer
 	 , @Spec_Desc 	 Varchar(50)
 	 , @Char_Id 	 Integer
    , @Char_Desc 	 Varchar(50)
 	 , @Start_Time 	 Datetime 
 	 , @DecimalSep 	 Varchar(1)= '.'
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003) 
-- Set Default Decimal Separator
If @DecimalSep is Null Set @DecimalSep = '.' 
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
DECLARE @Data_Type_Id 	 Int
DECLARE @Row_Count 	 Int
-- First Validate Specification Input
SELECT @Row_Count = 0
If @Spec_Id Is NULL AND @Spec_Desc Is NULL
  BEGIN
    SELECT [ReturnStatus] = -55 	  	 --input specification NOT SPECIFIED
    RETURN
  END
Else If @Spec_Desc Is NULL --we have @Spec_Id
  BEGIN
    SELECT @Spec_Desc = s.Spec_Desc, @Data_Type_Id = s.Data_Type_Id FROM Specifications s WHERE s.Spec_Id = @Spec_Id
    SELECT @Row_Count = @@ROWCOUNT
  END
Else 
  BEGIN
    SELECT @Spec_Id = s.Spec_Id, @Data_Type_Id = s.Data_Type_Id FROM Specifications s WHERE s.Spec_Desc = @Spec_Desc
    SELECT @Row_Count = @@ROWCOUNT
  END
--EndIf:Both @Spec_Id and @Spec_Desc null
If @Row_Count = 0 
  BEGIN
    SELECT ReturnStatus = -50 	  	 --the specified Specification NOT FOUND
    RETURN
  END
--EndIf
If ISNUMERIC(@Data_Type_Id) = 0
  BEGIN 
    SELECT ReturnStatus = -20 	  	 --"Illegal data type"
    RETURN
  END
--EndIf:Numeric
SELECT @Row_Count = 0
If @Char_Desc Is NOT NULL
  BEGIN
    SELECT @Char_Id = c.Char_Id FROM Characteristics c WHERE c.Char_Desc = @Char_Desc
    SELECT @Row_Count = @@ROWCOUNT
  END
Else If @Char_Id Is NOT NULL
  BEGIN
    SELECT @Char_Desc = c.Char_Desc FROM Characteristics c WHERE c.Char_Id = @Char_Id
    SELECT @Row_Count = @@ROWCOUNT
  END
Else --both @Char_Id and @Char_Desc are null (safeguard only, AddIn should have ruled this out.)
  BEGIN
    SELECT ReturnStatus = -75 	  	 --Tells the Add-In "No Characteristic Specified"
    RETURN
  END
--EndIf:
If @Row_Count = 0 
  BEGIN
    SELECT ReturnStatus = -70 	  	 --"Characteristic Specified Not Found"
    RETURN
  END
--EndIf
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
-- Added Transaction Comment; MSi/mt/9-7-2001
If @DecimalSep = '.' AND @Data_Type_Id = 2 
  BEGIN 
    SELECT Distinct a.AS_Id 
         , Effective_Date = a.Effective_Date at time zone @DBTz at time zone @InTimeZone
         , Expiration_Date = a.Expiration_Date at time zone @DBTz at time zone @InTimeZone
         , a.Test_Freq
         , a.Defined_By
         , a.Spec_Id
         , a.Deviation_From
         , a.Char_Id 
         , a.Comment_Id
         , a.Is_Defined
         , a.Is_OverRidable
         , a.Is_Deviation
         , a.Is_L_Rejectable
         , a.Is_U_Rejectable
         , [L_Warning] 
         , [L_Reject] 
         , [L_Entry]  
         , [U_User]   
         , [Target]   
         , [L_User]   
         , [U_Entry]  
         , [U_Reject] 
         , [U_Warning]
         , [U_Control] 	  	 -- ECR 31165
         , [T_Control] 	  	 -- ECR 31165
         , [L_Control] 	  	 -- ECR 31165
         , Trans_Comment_Id = t.Comment_Id
         , [Data_Type_Id] = @Data_Type_Id
      FROM Active_Specs a
     LEFT OUTER JOIN Transactions t ON t.Effective_Date = a.Effective_Date
     WHERE a.Spec_Id = @Spec_Id 
       AND a.char_id = @Char_Id 
       AND a.Effective_Date <= @Start_Time 
       AND (a.Expiration_Date > @Start_Time OR a.Expiration_Date IS NULL)
  END
ELSE --Not default Regional Separator; Must Set decimal separator to the specified Regional Decimal Separator
  BEGIN 
    SELECT Distinct a.AS_Id 
         , Effective_Date = a.Effective_Date at time zone @DBTz at time zone @InTimeZone
         , Expiration_Date = a.Expiration_Date at time zone @DBTz at time zone @InTimeZone
         , a.Test_Freq
         , a.Defined_By
         , a.Spec_Id
         , a.Deviation_From
         , a.Char_Id 
         , a.Comment_Id
         , a.Is_Defined
         , a.Is_OverRidable
         , a.Is_Deviation
         , a.Is_L_Rejectable
         , a.Is_U_Rejectable
         , [L_Warning] = REPLACE(a.L_Warning, '.', @DecimalSep)
         , [L_Reject]  = REPLACE(a.L_Reject, '.', @DecimalSep) 
         , [L_Entry]   = REPLACE(a.L_Entry, '.', @DecimalSep)  
         , [U_User]    = REPLACE(a.U_User, '.', @DecimalSep)   
         , [Target]    = REPLACE(a.Target, '.', @DecimalSep)   
         , [L_User]    = REPLACE(a.L_User, '.', @DecimalSep)   
         , [U_Entry]   = REPLACE(a.U_Entry, '.', @DecimalSep)  
         , [U_Reject]  = REPLACE(a.U_Reject, '.', @DecimalSep) 
         , [U_Warning] = REPLACE(a.U_Warning, '.', @DecimalSep)
         , [U_Control] = REPLACE(a.U_Control, '.', @DecimalSep) 	 -- ECR 31165
         , [T_Control] = REPLACE(a.T_Control, '.', @DecimalSep) 	 -- ECR 31165
         , [L_Control] = REPLACE(a.L_Control, '.', @DecimalSep) 	 -- ECR 31165
         , Trans_Comment_Id = t.Comment_Id 
         , [Data_Type_Id] = @Data_Type_Id
      FROM Active_Specs a
      LEFT OUTER JOIN Transactions t ON t.Effective_Date = a.Effective_Date
     WHERE a.Spec_Id = @Spec_Id 
       AND a.char_id = @Char_Id 
       AND a.Effective_Date <= @Start_Time 
       AND (a.Expiration_Date > @Start_Time OR a.Expiration_Date IS NULL)
  END
--EndIf:@DecimalSep ....
