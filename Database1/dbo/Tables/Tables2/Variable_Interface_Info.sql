CREATE TABLE [dbo].[Variable_Interface_Info] (
    [Var_Interface_Id] INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ED_Field_Type_Id] INT            NOT NULL,
    [Interface_Id]     INT            NOT NULL,
    [Qualifier_Desc]   VARCHAR (50)   NOT NULL,
    [Value]            VARCHAR (1000) NULL,
    [Var_Id]           INT            NOT NULL,
    CONSTRAINT [VarIntfaceInfo_PK_VarInterfaceId] PRIMARY KEY CLUSTERED ([Var_Interface_Id] ASC),
    CONSTRAINT [VarIntfaceInfo_FK_EDFieldType] FOREIGN KEY ([ED_Field_Type_Id]) REFERENCES [dbo].[ED_FieldTypes] ([ED_Field_Type_Id]),
    CONSTRAINT [VarIntfaceInfo_FK_ExternalInterfaces] FOREIGN KEY ([Interface_Id]) REFERENCES [dbo].[External_Interfaces] ([Interface_Id]),
    CONSTRAINT [VarIntfaceInfo_FK_Variables] FOREIGN KEY ([Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [VarIntfaceInfo_UC_InterfaceDesc] UNIQUE NONCLUSTERED ([Interface_Id] ASC, [Qualifier_Desc] ASC)
);

