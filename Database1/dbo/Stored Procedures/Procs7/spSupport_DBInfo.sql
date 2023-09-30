CREATE PROCEDURE dbo.spSupport_DBInfo  
@ShowFullTableInfo int = NULL
AS
Declare
  @DBName varchar(30),
  @HostName varchar(30),
  @Msg varchar(255),
  @NumLaps int,
  @NumTables int,
  @NumStoredProcedures int,
  @NumDefaults int,
  @NumTriggers int,
  @NumKeys int,
  @NumForiegnKeys int,
  @NumTypes int,
  @NumRules int,
  @@Name varchar(100)
Select @HostName 	 = Node_Name From CXS_Service Where Service_Id = 9
Select @DBName  	  	 = DB_NAME()
Select Name Into #Tables           From sys.sysobjects Where (Type = 'U') And (Name Not Like '%Local%')  	 Order By Name
Select Name Into #StoredProcedures From sys.sysobjects Where (Type = 'P') And (Name Not Like 'spLocal%') And (Name Not Like 'dt_%') 	 Order By Name
Select Name Into #Defaults         From sys.sysobjects Where (Type = 'D')   	  	  	  	  	 Order By Name
Select Name Into #Triggers         From sys.sysobjects Where (Type = 'TR')  	  	  	  	  	 Order By Name
Select Name Into #Keys             From sys.sysindexes Where (Id > 255) And (IndId <> 255) And (IndId <> 0) And (substring(name,1,1) <> '_') Order by Name
Select Name Into #ForiegnKeys      From sys.sysobjects Where (Type = 'F')  	  	  	  	  	 Order By Name
Select Name Into #Rules            From sys.sysobjects Where (Type = 'R')  	  	  	  	  	 Order By Name
Select Name Into #Types            From sys.systypes   Where UserType > 100  	  	  	  	 Order By Name
Select @NumTables  	  	 = Count(Name) From #Tables
Select @NumStoredProcedures  	 = Count(Name) From #StoredProcedures
Select @NumDefaults  	  	 = Count(Name) From #Defaults
Select @NumTriggers  	  	 = Count(Name) From #Triggers
Select @NumKeys  	  	 = Count(Name) From #Keys
Select @NumForiegnKeys  	  	 = Count(Name) From #ForiegnKeys
Select @NumTypes  	  	 = Count(Name) From #Types
Select @NumRules  	  	 = Count(Name) From #Rules
Select  	 @Msg = 'GradeBook Database Information as of ' + Convert(varchar(30),GetDate())
Print  	 @Msg
Print  	 ''
Select  	 @Msg = 'GradeBook Server.................................. ' + @HostName
Print  	 @Msg
Select  	 @Msg = 'Database.......................................... ' + @DBName
Print  	 @Msg
Select  	 @Msg = 'Number of User Defined Types...................... ' +  Convert(varchar(30),@NumTypes)
Print  	 @Msg
Select  	 @Msg = 'Number of User Defined Rules...................... ' +  Convert(varchar(30),@NumRules)
Print  	 @Msg
Select  	 @Msg = 'Number of Defaults................................ ' +  Convert(varchar(30),@NumDefaults)
Print  	 @Msg
Select  	 @Msg = 'Number of Triggers................................ ' +  Convert(varchar(30),@NumTriggers)
Print  	 @Msg
Select  	 @Msg = 'Number of Primary Keys, Indexes, Constraints...... ' +  Convert(varchar(30),@NumKeys)
Print  	 @Msg
Select  	 @Msg = 'Number of Foriegn Keys............................ ' +  Convert(varchar(30),@NumForiegnKeys)
Print  	 @Msg
Select  	 @Msg = 'Number of Stored Procedures....................... ' +  Convert(varchar(30),@NumStoredProcedures)
Print  	 @Msg
Select  	 @Msg = 'Number of Tables.................................. ' +  Convert(varchar(30),@NumTables)
Print  	 @Msg
Print   ''
Select  	 @Msg = 'Total Number of Objects........................... ' +  Convert(varchar(30),@NumTables + @NumStoredProcedures + @NumDefaults + @NumTriggers + @NumKeys + @NumForiegnKeys + @NumTypes + @NumRules)
Print  	 @Msg
Print  	 ''
Select  	 @Msg = 'User Defined Types'
Print  	 @Msg
Print '**********************************************************************'
Declare TBNs_Cursor INSENSITIVE CURSOR
  For (Select Name From #Types)
  For Read Only
  Open TBNs_Cursor  
Type_Loop:
  Fetch Next From TBNs_Cursor Into @@Name
  If (@@Fetch_Status = 0)
    Begin
      Print @@Name
      Goto Type_Loop
    End
Close TBNs_Cursor
Deallocate TBNs_Cursor
Print  	 ''
Select  	 @Msg = 'User Defined Rules'
Print  	 @Msg
Print '**********************************************************************'
Declare TBNs_Cursor INSENSITIVE CURSOR
  For (Select Name From #Rules)
  For Read Only
  Open TBNs_Cursor  
Rule_Loop:
  Fetch Next From TBNs_Cursor Into @@Name
  If (@@Fetch_Status = 0)
    Begin
      Print @@Name
      Goto Rule_Loop
    End
Close TBNs_Cursor
Deallocate TBNs_Cursor
Print  	 ''
Select  	 @Msg = 'Defaults'
Print  	 @Msg
Print '**********************************************************************'
Declare TBNs_Cursor INSENSITIVE CURSOR
  For (Select Name From #Defaults)
  For Read Only
  Open TBNs_Cursor  
Default_Loop:
  Fetch Next From TBNs_Cursor Into @@Name
  If (@@Fetch_Status = 0)
    Begin
      Print @@Name
      Goto Default_Loop
    End
Close TBNs_Cursor
Deallocate TBNs_Cursor
Print  	 ''
Select  	 @Msg = 'Triggers'
Print  	 @Msg
Print '**********************************************************************'
Declare TBNs_Cursor INSENSITIVE CURSOR
  For (Select Name From #Triggers)
  For Read Only
  Open TBNs_Cursor  
Trigger_Loop:
  Fetch Next From TBNs_Cursor Into @@Name
  If (@@Fetch_Status = 0)
    Begin
      Print @@Name
      Goto Trigger_Loop
    End
Close TBNs_Cursor
Deallocate TBNs_Cursor
Print  	 ''
Select  	 @Msg = 'Primary Keys, Indexes, Constraints'
Print  	 @Msg
Print '**********************************************************************'
Declare TBNs_Cursor INSENSITIVE CURSOR
  For (Select Name From #Keys)
  For Read Only
  Open TBNs_Cursor  
Key_Loop:
  Fetch Next From TBNs_Cursor Into @@Name
  If (@@Fetch_Status = 0)
    Begin
      Print @@Name
      Goto Key_Loop
    End
Close TBNs_Cursor
Deallocate TBNs_Cursor
Print  	 ''
Select  	 @Msg = 'Foriegn Keys'
Print  	 @Msg
Print '**********************************************************************'
Declare TBNs_Cursor INSENSITIVE CURSOR
  For (Select Name From #ForiegnKeys)
  For Read Only
  Open TBNs_Cursor  
FKey_Loop:
  Fetch Next From TBNs_Cursor Into @@Name
  If (@@Fetch_Status = 0)
    Begin
      Print @@Name
      Goto FKey_Loop
    End
Close TBNs_Cursor
Deallocate TBNs_Cursor
Print  	 ''
Select  	 @Msg = 'Stored Procedures'
Print  	 @Msg
Print '**********************************************************************'
Declare TBNs_Cursor INSENSITIVE CURSOR
  For (Select Name From #StoredProcedures)
  For Read Only
  Open TBNs_Cursor  
StoredProcedures_Loop:
  Fetch Next From TBNs_Cursor Into @@Name
  If (@@Fetch_Status = 0)
    Begin
      Print @@Name
      Goto StoredProcedures_Loop
    End
Close TBNs_Cursor
Deallocate TBNs_Cursor
Print  	 ''
Select  	 @Msg = 'Tables'
Print 	 @Msg
Print '**********************************************************************'
Select @NumLaps = 0
DoTheWork:
  Declare TBNs_Cursor INSENSITIVE CURSOR
    For (Select Name From #Tables)
    For Read Only
    Open TBNs_Cursor  
  Fetch_Loop:
    Fetch Next From TBNs_Cursor Into @@Name
    If (@@Fetch_Status = 0)
      Begin
 	 If @NumLaps = 0 
          Print @@Name
 	 If @NumLaps = 1
          Begin
 	     Print '**********************************************************************'
 	     Execute spSupport_TableInfo @@Name            
          End
        Goto Fetch_Loop
      End
  Close TBNs_Cursor
  Deallocate TBNs_Cursor
  Print ''
  Select @NumLaps = @NumLaps + 1
  If (@NumLaps < 2) And (@ShowFullTableInfo = 1)
    Goto DoTheWork
Print '**********************************************************************'
Drop Table #Tables
Drop Table #StoredProcedures
Drop Table #Defaults
Drop Table #Triggers
Drop Table #Keys
Drop Table #Rules
Drop Table #Types
