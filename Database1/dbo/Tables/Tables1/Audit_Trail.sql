CREATE TABLE [dbo].[Audit_Trail] (
    [Audit_Trail_Id]    INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Application_Id]    TINYINT        NOT NULL,
    [EndTime]           DATETIME       NULL,
    [Output_Parameters] VARCHAR (255)  NULL,
    [Parameters]        VARCHAR (4000) NULL,
    [ReturnCode]        INT            NULL,
    [Sp_Name]           VARCHAR (500)  NULL,
    [StartTime]         DATETIME       NOT NULL,
    [User_id]           INT            NOT NULL,
    CONSTRAINT [Audit_Trail_PK] PRIMARY KEY NONCLUSTERED ([Audit_Trail_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [AuditTrail_IDX_StartTime]
    ON [dbo].[Audit_Trail]([StartTime] ASC);

