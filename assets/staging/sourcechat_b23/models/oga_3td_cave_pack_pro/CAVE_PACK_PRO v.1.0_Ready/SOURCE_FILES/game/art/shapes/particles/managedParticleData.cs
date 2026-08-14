//-----------------------------------------------------------------------------
// Torque
// Copyright GarageGames, LLC 2011
//-----------------------------------------------------------------------------

// This is the default save location for any Particle datablocks created in the
// Particle Editor (this script is executed from onServerCreated())

datablock ParticleEmitterNodeData(DefaultParticleEmitterNodeData)
{
   timeMultiple = 1;
};

datablock ParticleData(ParticleMist)
{
   textureName = "art/shapes/particles/add_particles/mist.png";
   dragCoeffiecient = 0;
   gravityCoefficient = "-0.0854701";
   inheritedVelFactor = 0;
   constantAcceleration = -1;
   lifetimeMS = 2500;
   lifetimeVarianceMS = 0;
   useInvAlpha = 0;
   spinRandomMin = -125;
   spinRandomMax = 125;
   spinSpeed = 0.520833;

   colors[0] = "0.992126 0.992126 0.992126 0.436";
   colors[1] = "0.992126 0.992126 0.992126 0.465";
   colors[2] = "0.992126 0.992126 0.992126 0.668";
   colors[3] = "0.992126 0.992126 0.992126 0.23622";
   
   sizes[0] = 2;
   sizes[1] = 8;
   sizes[2] = 9;
   sizes[3] = "10.5";
   
   times[0] = 0.0;
   times[1] = "0.4";
   times[2] = "0.5";
   times[3] = "0.6";
   
   animTexName = "art/shapes/particles/add_particles/mist.png";
   
   dragCoefficient = "0.889541";
};

datablock ParticleData(ParticleMainFalls01)
{
   textureName = "art/shapes/particles/add_particles/main falls 01.png";
   animTexName = "art/shapes/particles/add_particles/main falls 01.png";
   gravityCoefficient = "0.788767";
   sizes[0] = "5.20662";
   sizes[1] = "14.5822";
   constantAcceleration = "0.416666";
   sizes[2] = "10.4163";
   sizes[3] = "0";
   lifetimeMS = "3001";
   inheritedVelFactor = "0.41683";
   times[1] = "0.329412";
   times[2] = "0.658824";
   colors[0] = "0.235294 0.403922 0.345098 1";
   colors[1] = "0.807843 0.85098 0.87451 1";
};

datablock ParticleData(ParticleMainFalls02)
{
   textureName = "art/shapes/particles/add_particles/main falls 02.png";
   animTexName = "art/shapes/particles/add_particles/main falls 02.png";
   gravityCoefficient = "0.788767";
   sizes[0] = "1.99902";
   sizes[1] = "7.99915";
   constantAcceleration = "0.416666";
   sizes[2] = "0";
   sizes[3] = "0";
   lifetimeMS = "2064";
};

datablock ParticleData(ParticleMainFalls03)
{
   textureName = "art/shapes/particles/add_particles/main falls 03.png";
   animTexName = "art/shapes/particles/add_particles/main falls 03.png";
   gravityCoefficient = "0.788767";
   sizes[0] = "1.99902";
   sizes[1] = "7.99915";
   constantAcceleration = "0.416666";
   sizes[2] = "0";
   sizes[3] = "0";
   lifetimeMS = "2064";
};

datablock ParticleData(ParticleRockImpactInner01)
{
   textureName = "art/shapes/particles/add_particles/rock_impact_1_inner.png";
   animTexName = "art/shapes/particles/add_particles/rock_impact_1_inner.png";
   gravityCoefficient = "0.541667";
   inheritedVelFactor = "1.875";
   spinSpeed = "0.229167";
   spinRandomMin = "-416";
   spinRandomMax = "541.9";
   colors[2] = "1 1 1 0.124481";
   colors[3] = "1 1 1 0.136929";
   sizes[1] = "3";
   sizes[2] = "3";
   sizes[3] = "3";
   times[1] = "0.25";
   times[2] = "0.6875";
};

datablock ParticleData(ParticleRockImpactTop)
{
   textureName = "art/shapes/particles/add_particles/top and top spray.png";
   animTexName = "art/shapes/particles/add_particles/top and top spray.png";
   gravityCoefficient = "0.124542";
   colors[1] = "0.996078 0.996078 0.996078 0.813";
   colors[2] = "1 1 1 0.581";
   colors[3] = "1 1 1 0.015748";
   sizes[1] = "1.99597";
   sizes[2] = "1.99597";
   sizes[3] = "1.99597";
   times[1] = "0.329412";
   times[2] = "0.658824";
   spinRandomMin = "-43";
   spinRandomMax = "42";
   colors[0] = "1 1 1 0";
   sizes[0] = "1.99597";
   times[3] = "0.992157";
};

datablock ParticleData(ParticleWaterDisturbance)
{
   textureName = "art/shapes/particles/add_particles/ripple.png";
   animTexName = "art/shapes/particles/add_particles/ripple.png";
   lifetimeMS = "2626";
   lifetimeVarianceMS = "49";
   spinRandomMin = "0";
   spinRandomMax = "5";
   colors[0] = "1 1 1 0.173228";
   colors[1] = "1 1 1 1";
   colors[2] = "1 1 1 0.409449";
   colors[3] = "1 1 1 0.0393701";
   sizes[1] = "10.6543";
   sizes[2] = "15.9952";
   sizes[3] = "18.6565";
   times[1] = "0.247059";
   times[2] = "0.513726";
   times[3] = "1";
   spinSpeed = "0";
   sizes[0] = "5.32564";
};

datablock ParticleEmitterData(EmitterMist)
{
   particles = "ParticleMist";
   blendStyle = "NORMAL";
   ejectionVelocity = "5.11";
   velocityVariance = "0";
   thetaMax = "165";
   softParticles = "1";
   ambientFactor = "0.416667";
   ejectionPeriodMS = "167";
};

datablock ParticleEmitterData(EmitterMainFalls)
{
   particles = "ParticleMainFalls01";
   blendStyle = "NORMAL";
   ejectionVelocity = "3.5";
   velocityVariance = "0";
   thetaMax = "10";
   ejectionPeriodMS = "146";
   softnessDistance = "1";
   orientParticles = "1";
   softParticles = "1";
   lifetimeMS = "0";
   ambientFactor = "0";
};

datablock ParticleEmitterData(EmitterMainFalls02)
{
   particles = "ParticleMainFalls02";
   blendStyle = "NORMAL";
   ejectionVelocity = "3.5";
   velocityVariance = "0";
   thetaMax = "10";
   ejectionPeriodMS = "146";
   softnessDistance = "1";
   orientParticles = "1";
   softParticles = "1";
   lifetimeMS = "0";
   ambientFactor = "0";
};

datablock ParticleEmitterData(EmitterMainFalls03)
{
   particles = "ParticleMainFalls03";
   blendStyle = "NORMAL";
   ejectionVelocity = "3.5";
   velocityVariance = "0";
   thetaMax = "25";
   ejectionPeriodMS = "146";
   softnessDistance = "1";
   orientParticles = "1";
   softParticles = "1";
   lifetimeMS = "0";
   ambientFactor = "0";
};

datablock ParticleEmitterData(EmitterTopSpray)
{
   particles = "ParticleRockImpactTop";
   blendStyle = "NORMAL";
   ejectionVelocity = "1";
   velocityVariance = "0";
   ejectionPeriodMS = "272";
   ambientFactor = "0";
   periodVarianceMS = "0";
   thetaMin = "0";
   thetaMax = "90";
   phiVariance = "360";
   alignParticles = "0";
   softParticles = "0";
};

datablock ParticleEmitterData(EmitterWaterDisturbance)
{
   particles = "ParticleWaterDisturbance";
   blendStyle = "NORMAL";
   thetaMin = "7";
   thetaMax = "180";
   orientParticles = "0";
   ejectionPeriodMS = "646";
   periodVarianceMS = "24";
   ejectionVelocity = "0";
   velocityVariance = "0";
   phiVariance = "1";
   alignParticles = "1";
   softnessDistance = "1";
   ambientFactor = "0";
   softParticles = "0";
   alignDirection = "0 0 1";
};

datablock ParticleEmitterData(EmitterRockImpact)
{
   particles = "ParticleRockImpactInner01";
   blendStyle = "NORMAL";
   ejectionPeriodMS = "167";
   velocityVariance = "0";
   softParticles = "1";
   softnessDistance = "1";
   ambientFactor = "0";
};

datablock ParticleEmitterData(EmitterTop)
{
   particles = "DefaultParticle";
   blendStyle = "NORMAL";
   ejectionPeriodMS = "417";
   ejectionVelocity = "69.05";
   velocityVariance = "59.81";
   ambientFactor = "0";
};


datablock ParticleData(ParticleSplinter)
{
   textureName = "art/shapes/particles/splinters.png";
   animTexName = "art/shapes/particles/splinters.png";
   lifetimeMS = "1501";
   lifetimeVarianceMS = "0";
   spinRandomMin = "-750";
   spinRandomMax = "666";
   colors[0] = "0.992126 0.992126 0.992126 1";
   colors[1] = "0.992126 0.992126 0.992126 1";
   colors[2] = "0.992126 0.992126 0.992126 1";
   colors[3] = "0.992126 0.992126 0.992126 1";
   sizes[1] = "0.25";
   sizes[2] = "0.25";
   sizes[3] = "0";
   times[1] = "0.247059";
   times[2] = "0.513726";
   times[3] = "0.686275";
   spinSpeed = "1";
   sizes[0] = "0.5";
   gravityCoefficient = "0.542";
   inheritedVelFactor = "0.833";
   constantAcceleration = "0.417";
};

datablock ParticleData(ParticleSteamData)
{
   textureName = "art/shapes/particles/smoke2.png";
   animTexName = "art/shapes/particles/smoke2.png";
   lifetimeMS = "5000";
   lifetimeVarianceMS = "250";
   spinRandomMin = "-25";
   spinRandomMax = "25";
   colors[0] = "0.992126 0.992126 0.992126 0";
   colors[1] = "0.992126 0.992126 0.992126 0.207";
   colors[2] = "0.992126 0.992126 0.992126 0";
   colors[3] = "0.992126 0.992126 0.992126 1";
   sizes[1] = "33.3303";
   sizes[2] = "31.2489";
   sizes[3] = "0";
   times[1] = "0.498039";
   times[2] = "1";
   times[3] = "1";
   spinSpeed = "0.05";
   sizes[0] = "27.083";
   gravityCoefficient = "0";
   inheritedVelFactor = "0";
   constantAcceleration = "0";
};

datablock ParticleEmitterData(ParticleSteamEmitter)
{
   ejectionPeriodMS = "271";
   periodVarianceMS = "208";
   ejectionVelocity = 0;
   velocityVariance = 0;
   thetaMin         = 0.0;
   thetaMax         = 39;
   lifetimeMS       = 0;
   particles = "ParticleSteamData";
   blendStyle = "NORMAL";
   ejectionOffset = "0";
   softnessDistance = "1";
   softParticles = "1";
   lifetimeVarianceMS = "0";
};

datablock ParticleData(WaterVortexParticle)
{
   textureName = "art/shapes/particles/add_particles/rock impact top and side spray.png";
   animTexName = "art/shapes/particles/add_particles/rock impact top and side spray.png";
   lifetimeMS = "8000";
   lifetimeVarianceMS = "4800";
   spinRandomMin = "-100";
   spinRandomMax = "120";
   colors[0] = "0.643137 0.643137 0.643137 0.141";
   colors[1] = "0.913726 0.909804 0.909804 0.763";
   colors[2] = "0.917647 0.913726 0.913726 0.726";
   colors[3] = "0.933333 0.929412 0.929412 0.11811";
   sizes[1] = "8";
   sizes[2] = "4";
   sizes[3] = "2";
   times[1] = "0.25";
   times[2] = "0.5";
   times[3] = "0.8";
   spinSpeed = "0.4";
   sizes[0] = "11";
   constantAcceleration = "-2.5";
   inheritedVelFactor = "1";
};

datablock ParticleEmitterData(WaterVortexEmitter)
{
   particles = "WaterVortexParticle";
   blendStyle = "NORMAL";
   thetaMin = "7";
   thetaMax = "180";
   orientParticles = "0";
   ejectionPeriodMS = "646";
   periodVarianceMS = "24";
   ejectionVelocity = "0";
   velocityVariance = "0";
   phiVariance = "360";
   alignParticles = "0";
   softnessDistance = "1";
   ambientFactor = "0";
   softParticles = "1";
   ejectionOffset = "0";
};
