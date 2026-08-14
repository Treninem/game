//-----------------------------------------------------------------------------
// Torque
// Copyright GarageGames, LLC 2011
//-----------------------------------------------------------------------------

// This is the default save location for any Particle Emitter datablocks created in the
// Particle Editor (this script is executed from onServerCreated())

datablock ParticleEmitterData(TeleportFlash_Emitter : DefaultEmitter)
{
   ejectionVelocity = "0.1";
   particles = "TeleporterFlash";
   thetaMax = "180";
   softnessDistance = "1";
   ejectionOffset = "0.417";
};