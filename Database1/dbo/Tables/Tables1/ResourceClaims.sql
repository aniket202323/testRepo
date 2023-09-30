CREATE TABLE [dbo].[ResourceClaims] (
    [ResourceClaimId] UNIQUEIDENTIFIER NOT NULL,
    [ResourceId]      NVARCHAR (2048)  NULL,
    [Scope]           SMALLINT         NULL,
    [Version]         BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([ResourceClaimId] ASC)
);

