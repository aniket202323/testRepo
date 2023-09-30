Create Procedure dbo.spEM_TransGetLimitDef 
 	 @Char_Id 	 int,
 	 @Spec_Id 	 int,
 	 @Limit 	  	 int,
 	 @Current 	 TinyInt,
 	 @Now 	  	 DateTime,
 	 @Trans_Id 	 Int,
 	 @Value 	  	 nVarChar(25) Output,
 	 @ISTrans 	 tinyint Output
 AS
-- current = 1 - Start at current Characterstic
-- current = 0 - look up tree for limit
Declare 	  	 @PrevChar 	 int,
 	  	 @Defined 	 Int,
 	  	 @MovedUp 	 Int,
 	  	 @CurrentValue   nvarchar(25),
 	  	 @MovedUpUndefined Int
Select @CurrentValue = @Value
Select @Value = Null,@ISTrans = 0,@MovedUp = 0,@MovedUpUndefined = 0
Select @MovedUpUndefined = case when Not_Defined & @Limit = @Limit then 1
 	  	  	      Else 0
 	  	  	      End
 	  From Trans_Properties
 	  Where Spec_Id = @Spec_Id and Char_Id = @Char_Id  And Trans_Id = @Trans_Id
NextChar:
  Select @PrevChar = Null
  Select @PrevChar = To_Char_Id 
    From Trans_Char_Links
    Where From_Char_Id = @Char_Id and Trans_Id = @Trans_Id
  If @PrevChar is null
     Select @PrevChar = Derived_From_Parent From Characteristics Where Char_Id = @Char_Id
  If @Current = 1
    Begin
      Select @PrevChar = @Char_Id
      Select  @Current = 0
    End
  If @PrevChar is not Null
    Begin
      Select @MovedUp = 1
      Select @Defined = Null
      Select @Defined = Not_Defined
 	  From Trans_Properties
 	  Where Spec_Id = @Spec_Id and Char_Id = @PrevChar  And Trans_Id = @Trans_Id
      If @Defined & @Limit = @Limit  and @Defined is not null -- limit removal
       Begin
        Select @Char_Id = @PrevChar,@MovedUpUndefined = 1
        GoTo NextChar
       End
      Select @Defined = Null
      Select @Defined = Is_Defined
 	  From Trans_Properties
 	  Where Spec_Id = @Spec_Id and Char_Id = @PrevChar  And Trans_Id = @Trans_Id
       	 If @Defined & @Limit = @Limit
        	  Begin
          Select @Value = Case 	 When @Limit = 1     Then L_Entry
 	  	  	  	 When @Limit = 2     Then L_Reject
 	  	  	  	 When @Limit = 4     Then L_Warning
 	  	  	  	 When @Limit = 8     Then L_User
 	  	  	  	 When @Limit = 16   Then Target
 	  	  	  	 When @Limit = 32   Then U_User
 	  	  	  	 When @Limit = 64   Then U_Warning
 	  	  	  	 When @Limit = 128 Then U_Reject
 	  	  	  	 When @Limit = 256 Then U_Entry
 	  	  	  	 When @Limit = 512 Then Convert(nvarchar(25),Test_Freq)
 	  	  	  	 When @Limit = 1024 Then Convert(nvarchar(25),Esignature_Level)
 	  	  	  	 When @Limit = 8192 Then L_Control
 	  	  	  	 When @Limit = 16384 Then T_Control
 	  	  	  	 When @Limit = 32768 Then U_Control
 	  	  	 End
 	  From Trans_Properties
 	  Where Spec_Id = @Spec_Id and Char_Id = @PrevChar  And Trans_Id = @Trans_Id
 	  Select @ISTrans = 1
          Return                        
        End
      Select @Defined = Is_Defined
 	  From Active_Specs
 	  Where Spec_Id = @Spec_Id and Char_Id = @PrevChar  And
 	  	     Effective_Date <= @Now And  ((Expiration_Date IS NULL) Or
             	  	    ((Expiration_Date IS NOT NULL) And  (Expiration_Date > @Now)))
      If @Defined & @Limit = @Limit
       Begin
         Select @Value = Case 	 
 	  	  	  	 When @Limit = 1     Then L_Entry
 	  	  	  	 When @Limit = 2     Then L_Reject
 	  	  	  	 When @Limit = 4     Then L_Warning
 	  	  	  	 When @Limit = 8     Then L_User
 	  	  	  	 When @Limit = 16   Then Target
 	  	  	  	 When @Limit = 32   Then U_User
 	  	  	  	 When @Limit = 64   Then U_Warning
 	  	  	  	 When @Limit = 128 Then U_Reject
 	  	  	  	 When @Limit = 256 Then U_Entry
 	  	  	  	 When @Limit = 512 Then Convert(nvarchar(25),Test_Freq)
 	  	  	  	 When @Limit = 1024 Then Convert(nvarchar(25),Esignature_Level)
 	  	  	  	 When @Limit = 8192 Then L_Control
 	  	  	  	 When @Limit = 16384 Then T_Control
 	  	  	  	 When @Limit = 32768 Then U_Control
 	  	  	 End
 	  From Active_Specs
 	  Where Spec_Id = @Spec_Id and Char_Id = @PrevChar  And
 	  	     Effective_Date <= @Now And  ((Expiration_Date IS NULL) Or (Expiration_Date > @Now))
 	 IF @MovedUpUndefined = 1 
 	  	 Select @ISTrans = 1
 	 ELSE 
 	  	 Select @ISTrans = 0
          Return                        
       End
    Else
     Begin
        Select @Char_Id = @PrevChar
        GoTo NextChar
     End
  End
If @MovedUpUndefined = 1 and @Value is null
  Select @Value = '',@ISTrans = 1
Else If @MovedUp = 1 and @Value is null
  Select @Value = Case  When @CurrentValue Is Null Then Null
 	  	  	 Else ''
                  End,
 	 @ISTrans = Case  When @CurrentValue Is Null Then 0
 	  	  	 Else 1
                  End
Return
