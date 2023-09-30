CREATE TABLE [dbo].[ServiceProvider_Stored_Procedure] (
    [Stored_Procedure_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Stored_Procedure_Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [ServiceProv_PK_SpId] PRIMARY KEY NONCLUSTERED ([Stored_Procedure_Id] ASC),
    CONSTRAINT [ServiceProv_UC_SpName] UNIQUE NONCLUSTERED ([Stored_Procedure_Name] ASC)
);

