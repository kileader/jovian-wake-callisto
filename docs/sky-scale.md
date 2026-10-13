# How large should Jupiter look from Callisto?

For a spherical body of radius R at observer-to-center distance d:

`angular diameter = 2 × asin(R / d)`

JPL lists Jupiter's equatorial radius as **71,492 km** and Callisto's mean orbital semimajor axis as **1,882,700 km**. This gives an approximate equatorial angular diameter of **4.35245°**. The code also includes Callisto's 2,410.3 km surface offset for the chosen site and uses an oblate Jupiter mesh. The small differences due to orbital eccentricity, surface location, and polar flattening do not turn it into a planet covering half the sky.

At 720 pixels tall with a 75° vertical field of view, that diameter projects to approximately **36 pixels**. At the held 20° visor field of view it projects to approximately **155 pixels**. Both views depict the same physical apparent angle: the visor narrows the camera's field of view.

`pixel diameter = image height × tan(angular diameter / 2) / tan(vertical FOV / 2)`

The Sun's approximate radius of 696,000 km at a representative Jupiter–Sun distance of 778 million km gives **0.1025°** across, less than one pixel in the normal 720p view. A small artistic optical glare helps identify it; that glare does not change the disk's angular size. Its direction is to the right of Jupiter and also controls the directional light.

Io, Europa, and Ganymede use the same size calculation, with their observer distances computed from a simple coplanar circular-orbit arrangement. They appear as very small disks/points, more readable through the visor. The visor names the sky body near the center of the view, and hides its crosshair so it does not cover small disks. The chosen phases are representative scene parameters, not predictions of their positions on October 13, 2026. The scene does not simulate orbital motion, eclipses, a complete atmospheric photometric model, or a live ephemeris.

## Sources

- [JPL planetary physical parameters](https://ssd.jpl.nasa.gov/planets/phys_par.html): Jupiter equatorial/mean radii. An approximate polar radius of 66,853 km follows from the oblate spheroid volume relation using those two radii.
- [JPL satellite mean orbital elements](https://ssd.jpl.nasa.gov/sats/elem/): Callisto and the inner Galilean moon orbit sizes.
- [JPL satellite physical parameters](https://ssd.jpl.nasa.gov/sats/phys_par/): Callisto, Io, Europa, and Ganymede mean radii.
- [NASA solar-system scale overview](https://science.nasa.gov/learning-resources/how-big-is-the-solar-system/): representative Jupiter–Sun distance.
- [NASA Astrobiology Math](https://www.nasa.gov/wp-content/uploads/2013/05/637832main_astrobiology_math.pdf): approximate solar radius used for this prototype.

Exact sky configurations for a selected time/site would require an ephemeris such as [JPL Horizons](https://ssd.jpl.nasa.gov/sats/orbits.html). That is outside this static playground's scope.
