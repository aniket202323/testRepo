CREATE TABLE [dbo].[Calculation_Dependency_Data] (
    [Calc_Dependency_Id] INT NOT NULL,
    [Result_Var_Id]      INT NOT NULL,
    [Var_Id]             INT NOT NULL,
    CONSTRAINT [PK_Calculation_Dependency_Data] PRIMARY KEY NONCLUSTERED ([Calc_Dependency_Id] ASC, [Result_Var_Id] ASC),
    CONSTRAINT [FK_Calculation_Dependency_Data_Calculation_Dependencies] FOREIGN KEY ([Calc_Dependency_Id]) REFERENCES [dbo].[Calculation_Dependencies] ([Calc_Dependency_Id]),
    CONSTRAINT [FK_Calculation_Dependency_Data_Variables] FOREIGN KEY ([Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [FK_Calculation_Dependency_Data_Variables2] FOREIGN KEY ([Result_Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id])
);


GO
Create  TRIGGER dbo.CalculationDependencyData_Reload_InsUpdDel
 	 ON dbo.Calculation_Dependency_Data
 	 FOR INSERT, UPDATE, DELETE
 	 AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 	 Declare @ShouldReload Int
 	 Select @ShouldReload = sp.Value 
 	  	 From Parameters p
 	  	 Join Site_Parameters sp on p.Parm_Id = sp.Parm_Id
 	  	 Where Parm_Name = 'Perform automatic service reloads'
 	 If @ShouldReload is null or @ShouldReload = 0 
 	  	 Return
/*
2  -Database Mgr
4  -Event Mgr
5  -Reader
6  -Writer
7  -Summary Mgr
8  -Stubber
9  -Message Bus
14 -Gateway
16 -Email Engine
17 -Alarm Manager
18 -FTP Engine
19 -Calculation Manager
20 -Print Server
22 -Schedule Mgr
*/
Update cxs_service set Should_Reload_Timestamp = DateAdd(minute,5,dbo.fnServer_CmnGetDate(getUTCdate())) where Service_Id in (19)
