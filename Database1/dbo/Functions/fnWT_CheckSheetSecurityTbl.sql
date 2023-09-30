CREATE FUNCTION [dbo].[fnWT_CheckSheetSecurityTbl]
(
  	  @DisplayOptions dbo.DisplayOptions READONLY,
  	  @SecurityOptions dbo.SheetSecurityOptions READONLY,
  	  @UnitId int, 
  	  @DtOption  	  Int, 
  	  @DtpOption  	  Int,
  	  @DefaultLevel  	  Int,
  	  @UsersSecurity  	  Int
) 
RETURNS  
@TmpDisplayOptions TABLE
(
   	   [PU_Id] [int] NULL,
   	   [MasterUnit] [int] NULL,
   	   [AddSecurity] [int] NULL,
   	   [DeleteSecurity] [int] NULL,
   	   [CloseSecurity] [int] NULL,
   	   [OpenSecurity] [int] NULL,
   	   [EditStartTimeSecurity] [int] NULL,
   	   [AddComments] [int] NULL,
   	   [AssignReasons] [int] NULL,
   	   [ChangeComments] [int] NULL,
   	   [ChangeFault] [int] NULL,
   	   [ChangeLocation] [int] NULL,
   	   [OverlapRecords] [int] NULL,
   	   [SplitRecords] [int] NULL,
   	   [CopyPasteReasons&Fault] [int] NULL,
  	   [CopyFault] [int] NULL,
  	   [CopyReasons] [int] NULL,
   	   [UsersSecurity] [int] NULL
)
AS 
BEGIN
   	   Declare @Start Int, @End Int,@PUId Int,@UserId Int
   	   DECLARE @UnitsToProcess Table (Id Int Identity (1,1),MasterId Int)
   	   Insert into @TmpDisplayOptions
   	   Select * from @DisplayOptions
   	   Declare @DisplayOptionsValue Table(Display_Option_Id Int, Sheet_Type_Id Int, Sheet_Id Int,Master_Unit Int,PU_Id Int,aValue varchar(7000),SecurityType varchar(50),rownum int)
   	   ;WITH ActiveSheets As 
   	   (
   	      	   Select distinct s.Sheet_Type,SU.PU_Id,s.Master_Unit,s.Sheet_Id from Sheet_Unit su join Sheets s on s.Sheet_Id = su.Sheet_Id --and s.Is_Active = 1 
   	      	   where su.PU_Id in (select ISNULL(MasterUnit,pu_id) from @TmpDisplayOptions) 
   	      	   AND s.Sheet_Type in (4,29,26)
   	      	   AND s.Is_Active = 1
 	  	  	   UNION
 	  	  	   Select distinct s.Sheet_Type,NULL,s.Master_Unit,s.Sheet_Id from Sheets s
   	      	   where S.Master_Unit in (select ISNULL(MasterUnit,pu_id) from @TmpDisplayOptions)
   	      	   AND s.Sheet_Type in (4,29,26)
   	      	   AND s.Is_Active = 1
   	   )
   	   ,DefaultSecurityValues As 
   	   (
   	      	   Select 
   	      	      	   Display_Option_Id,Sheet_Type_Id,Display_option_default,Sheet_Id,PU_Id ,Master_Unit
   	      	   from 
   	      	      	   Sheet_Type_Display_Options A
   	      	      	   Join ActiveSheets Ac On Ac.Sheet_Type = A.Sheet_Type_Id
    	   )
   	   ,ActualSecurityValues As 
   	   (
   	      	   Select 
   	      	      	   a.Display_Option_Id,Sheet_Type_Id,s.Sheet_Id,Master_Unit,PU_Id,a.Value
   	      	   from 
   	      	      	   Sheet_Display_options a  WITH (nolock) 
    	      	      	   Join display_Options b  WITH (nolock)  on b.Display_Option_Id = a.Display_Option_Id
    	      	      	   Join Sheet_Type_Display_Options c   WITH (nolock)  on c.Display_Option_Id = b.Display_Option_Id 
    	      	      	   Join Sheets s  WITH (nolock)  on s.Sheet_Id = a.Sheet_Id And s.Is_Active = 1
    	      	      	   Left Join Sheet_Unit su  WITH (nolock)  on su.sheet_Id = s.sheet_Id
   	      	   Where su.PU_Id in (select ISNULL(MasterUnit,pu_id) from @TmpDisplayOptions) Or s.Master_Unit in (select ISNULL(MasterUnit,pu_id) from @TmpDisplayOptions)
   	   )
   	   ,DisplayOption_SecurityType as 
   	   (
   	      	   Select 8 Display_option_id, 'AddSecurity' SecurityType UNION Select 393 Display_option_id, 'AddSecurity' SecurityType
   	      	   UNION
   	      	   Select 7 Display_option_id, 'DeleteSecurity' SecurityType UNION Select 392 Display_option_id, 'DeleteSecurity' SecurityType 
   	      	   UNION 
 	  	  	   Select 388, 'AddComments' UNION Select 389,'AssignReasons' UNION Select 403, 'ChangeAmount'
 	  	  	   UNION Select 390,'ChangeComments' UNION Select 400, 'ChangeFault' UNION Select 401, 'ChangeLocation'
 	  	  	   UNION Select 397, 'ChangeTime' UNION Select 391,'CopyPasteReasons&Fault' UNION Select 402, 'FilterDisplay'
 	  	  	   UNION Select 467 ,'CopyReasons'
   	   )
   	   Insert Into @DisplayOptionsValue
   	   Select 
   	      	   S.Display_Option_Id,S.Sheet_Type_Id,s.Sheet_Id,S.Master_Unit,S.PU_Id,ISNULL(S1.Value,S.Display_Option_Default) Value,Dstype.SecurityType
   	      	   ,Case when S.Display_Option_Id <> 467 then row_number() Over (partition by ISNULL(S.Master_Unit,S.PU_Id),Dstype.SecurityType order by Case When s.Sheet_Type_Id =29 THEN 1 When s.Sheet_Type_Id =4 THEN 2 When s.Sheet_Type_Id =26 THEN 3 END) Else row_number() over (partition by ISNULL(S.Master_Unit,S.PU_Id),Dstype.SecurityType Order by Value Asc) End
   	   from 
   	      	   DefaultSecurityValues S 
   	      	   join DisplayOption_SecurityType Dstype on Dstype.Display_Option_Id =s.Display_Option_Id
   	      	   LEFT OUTER JOIN ActualSecurityValues S1 oN S.Display_Option_Id = S1.Display_option_Id and S.Sheet_Type_Id = S1.Sheet_Type_Id 
   	      	   AND ISNULL(S.Master_Unit,S.Pu_Id) = ISNULL(S1.Master_Unit,S1.Pu_Id) 
   	      	   AND S.Sheet_Id = S1.Sheet_Id
   	   ;WITH ActiveSheets As 
    	    (
    	        	    Select distinct s.Sheet_Type,SU.PU_Id,s.Master_Unit,s.Sheet_Id from Sheet_Unit su right outer join Sheets s on s.Sheet_Id = su.Sheet_Id --and s.Is_Active = 1 
    	        	    where (su.PU_Id in (select ISNULL(MasterUnit,pu_id) from @TmpDisplayOptions) or S.Master_Unit in (select ISNULL(MasterUnit,pu_id) from @TmpDisplayOptions))
    	        	    AND s.Sheet_Type in (4,29,26)
    	        	    AND s.Is_Active = 1
    	    ), FinalRslt AS 
    	    (
    	        	    Select
    	        	        	    s.SecurityType,S.Pu_Id, 
   	      	      	    CASE WHEN v.Display_Option_Id = 467 then Min(v.aValue) else CASE WHEN u.UsersSecurity >= ISNULL(Min(v.aValue),s.DefaultLevel) Then 1 Else 0 End end Value
    	        	    from
    	        	        	    @SecurityOptions s
    	        	        	    Join @TmpDisplayOptions U on ISNULL(U.MasterUnit,U.PU_Id) = Isnull(s.masterUnit,s.PU_Id)
    	        	        	    Left join @DisplayOptionsValue v on v.SecurityType = s.SecurityType and ISNULL(v.Master_Unit,v.PU_Id) = Isnull(s.masterUnit,s.PU_Id) and v.rownum =1
    	        	    Where Exists (Select 1 from ActiveSheets)
  	    	    	    Group By s.SecurityType,s.PU_Id,s.DefaultLevel,u.UsersSecurity,v.Display_Option_Id
    	    )
   	   ,FinalRslt_Pivot As 
   	   (
   	      	   Select 
   	      	      	   Pu_Id,[AddSecurity],[DeleteSecurity],[AddComments],[AssignReasons],[ChangeAmount],[ChangeComments],[ChangeFault],
 	  	  	  	  	   [ChangeLocation],[ChangeTime],[CopyPasteReasons&Fault],[FilterDisplay],[CopyReasons]
   	      	   from 
   	      	      	   FinalRslt
   	      	      	   PIVOT 
   	      	      	   (
   	      	      	      	      	   AVG(Value) FOR SecurityType in 
   	      	      	      	      	   (
   	      	      	      	      	      	 [AddSecurity],[DeleteSecurity],[AddComments],[AssignReasons],[ChangeAmount],[ChangeComments],[ChangeFault],
 	  	  	  	  	  	  	  	  	  	  	 [ChangeLocation],[ChangeTime],[CopyPasteReasons&Fault],[FilterDisplay],[CopyReasons]
   	      	      	      	      	   )
   	      	      	   )pvt
   	   )
   	   UPDATE A 
   	   SET
   	      	   A.[AddComments] = ISNULL(B.AddComments,0),
   	      	   A.[AddSecurity] = ISNULL(B.AddSecurity,0),
   	      	   A.[AssignReasons] = ISNULL(B.AssignReasons,0),
   	      	   A.[ChangeComments] = ISNULL(B.ChangeComments,0),
   	      	   A.[ChangeFault] = ISNULL(B.ChangeFault,0),
   	      	   A.[ChangeLocation] = ISNULL(B.ChangeLocation,0),
   	      	   A.[CloseSecurity] = ISNULL(B.ChangeAmount,0),
   	      	   A.[CopyPasteReasons&Fault] = ISNULL(B.[CopyPasteReasons&Fault],0),
   	      	   A.[DeleteSecurity] = ISNULL(B.DeleteSecurity,0),
   	      	   A.[OverlapRecords] = 0,
   	      	   A.[SplitRecords] = ISNULL(B.FilterDisplay,0),
   	      	   A.openSecurity = ISNULL(B.ChangeTime,0),
   	      	   A.editStartTimeSecurity = 0,
  	    	   A.CopyFault = CASE WHEN ISNULL(B.CopyReasons,1) IN (1,2) THEN 1 ELSE 0 END,
  	    	   A.CopyReasons = CASE WHEN ISNULL(B.CopyReasons,1) IN (1,3) THEN 1 ELSE 0 END
   	   from 
   	      	   @TmpDisplayOptions A 
   	      	   join FinalRslt_Pivot B on B.PU_Id = A.MasterUnit
 	 RETURN
END
