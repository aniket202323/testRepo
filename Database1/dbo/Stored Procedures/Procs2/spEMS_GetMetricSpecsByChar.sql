--  spEMS_GetMetricSpecsByChar 136,9641
CREATE PROCEDURE dbo.spEMS_GetMetricSpecsByChar 
  @Char_Id int,
  @Trans_Id Int,
  @DecimalSep     nVarChar(2) = '.'
  AS
  --
  DECLARE  	 @AS_Id    	  	  	 Int,
 	  	  	 @Effective_Date  	 DateTime,
 	  	  	 @Expiration_Date  	 DateTime,
 	  	  	 @Prop_Id 	  	  	 Int
  Select @Prop_Id = Prop_Id  From Characteristics where Char_Id = @Char_Id
  Create table #ActiveSpecs (Spec_Id Int,Char_Id Int,U_Entry nVarChar(25),U_Reject nVarChar(25),
 	  	  	  	  	  	  	 U_Warning nVarChar(25),U_User nVarChar(25),Target nVarChar(25),L_User nVarChar(25),
 	  	  	  	  	  	  	 L_Warning nVarChar(25),L_Reject nVarChar(25),L_Entry nVarChar(25),L_Control nVarChar(25),T_Control nVarChar(25),
 	  	  	  	  	  	  	 U_Control nVarChar(25),Esignature_Level Int,
 	  	  	  	  	  	  	 Comment_Id Int,Expiration_Date DateTime,Effective_Date DateTime,AS_Id Int,Test_Freq Int)
  Declare  MetricSpecs_Cursor Cursor For
 	 Select Min(AS_Id),Effective_Date 
 	 From Active_Specs
 	  Where Char_Id = @Char_Id
 	 Group by Effective_Date 
Open MetricSpecs_Cursor
MetricSpecsLoop:
 Fetch Next From  MetricSpecs_Cursor Into @AS_Id,@Effective_Date
 If @@Fetch_Status = 0
   Begin
 	 Insert Into #ActiveSpecs
   	  	 SELECT s.Spec_Id,
         Char_Id = @Char_Id,
         U_Entry = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.U_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.U_Entry
 	  	  	  	  	  	 End,
         U_Reject = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.U_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.U_Reject
 	  	  	  	  	  	 End,
         U_Warning = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.U_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.U_Warning
 	  	  	  	  	  	 End,
         U_User = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.U_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.U_User
 	  	  	  	  	  	 End,
         Target = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.Target, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.Target
 	  	  	  	  	  	 End,
         L_User = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.L_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.L_User
 	  	  	  	  	  	 End,
         L_Warning = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.L_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.L_Warning
 	  	  	  	  	  	 End,
         L_Reject = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.L_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.L_Reject
 	  	  	  	  	  	 End,
         L_Entry = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.L_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.L_Entry
 	  	  	  	  	  	 End,
         L_Control = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.L_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.L_Control
 	  	  	  	  	  	 End,
         T_Control = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.T_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.T_Control
 	  	  	  	  	  	 End,
         U_Control = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.U_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.U_Control
 	  	  	  	  	  	 End,
         a.Esignature_Level,
         a.Comment_Id,
         Expiration_Date = a.Expiration_Date,
 	  	  Effective_Date = @Effective_Date,
         AS_Id = @AS_Id,
 	  	  a.Test_Freq
 	 From Specifications s
 	 Left Join Active_Specs a on a.spec_Id = s.Spec_Id and a.Effective_Date = @Effective_Date  and a.Char_Id = @Char_Id
 	 Where s.Prop_Id = @Prop_Id
 	 Order by a.Effective_Date
 	 GoTo MetricSpecsLoop
   End
Close MetricSpecs_Cursor
Deallocate MetricSpecs_Cursor
insert Into #ActiveSpecs  --add new columns
  Select s.Spec_Id,Char_Id,Null,Null,Null ,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Effective_Date,AS_Id,Null
   From Trans_Metric_Properties
   Right join Specifications s on s.Prop_Id = @Prop_Id
 Where Trans_Id = @Trans_Id and Char_Id = @Char_Id and Effective_Date not in (Select distinct Effective_Date From #ActiveSpecs)
Select * From #ActiveSpecs order by Effective_Date
Drop Table #ActiveSpecs
Select Spec_Id,Char_Id,U_Entry,U_Reject,U_Warning ,U_User,Target,L_User,
 	    L_Warning,L_Reject,L_Entry,L_Control,T_Control,U_Control,Esignature_Level,Effective_Date,AS_Id
From Trans_Metric_Properties
Where Trans_Id = @Trans_Id and Char_Id = @Char_Id
Order by Effective_Date
