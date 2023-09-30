CREATE TABLE [dbo].[ServiceProvider_Stored_Procedure_Field] (
    [Stored_Procedure_Field_Id] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Data_Type]                 VARCHAR (20)  NOT NULL,
    [Field_Description]         VARCHAR (255) NULL,
    [Field_Name]                VARCHAR (50)  NOT NULL,
    [Stored_Procedure_Id]       INT           NOT NULL,
    [Table_Name]                VARCHAR (50)  NOT NULL,
    [Table_Number]              INT           NOT NULL,
    CONSTRAINT [ServiceProvField_PK_SpId] PRIMARY KEY NONCLUSTERED ([Stored_Procedure_Field_Id] ASC),
    CONSTRAINT [ServiceProvField_FK_SpId] FOREIGN KEY ([Stored_Procedure_Id]) REFERENCES [dbo].[ServiceProvider_Stored_Procedure] ([Stored_Procedure_Id]),
    CONSTRAINT [ServiceProvField_UC_SpTableNumFieldName] UNIQUE NONCLUSTERED ([Stored_Procedure_Id] ASC, [Table_Number] ASC, [Field_Name] ASC)
);

