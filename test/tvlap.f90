  !
!     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
!     *                                                               *
!     *                  copyright (c) 1998 by UCAR                   *
!     *                                                               *
!     *       University Corporation for Atmospheric Research         *
!     *                                                               *
!     *                      all rights reserved                      *
!     *                                                               *
!     *                      SPHEREPACK version 3.2                   *
!     *                                                               *
!     *       A Package of Fortran77 Subroutines and Programs         *
!     *                                                               *
!     *              for Modeling Geophysical Processes               *
!     *                                                               *
!     *                             by                                *
!     *                                                               *
!     *                  John Adams and Paul Swarztrauber             *
!     *                                                               *
!     *                             of                                *
!     *                                                               *
!     *         the National Center for Atmospheric Research          *
!     *                                                               *
!     *                Boulder, Colorado  (80307)  U.S.A.             *
!     *                                                               *
!     *                   which is sponsored by                       *
!     *                                                               *
!     *              the National Science Foundation                  *
!     *                                                               *
!     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
!
!
!
!
!     1/976
!
!     a program for testing all vector laplacian and its inverse
!
!     (1) first set the vector function (rotation about equator) using
!         v = cos(phi) and w = -cos(theta)*sin(phi)
!
!     (2) set vector laplacian ananlytically
!         vlap = -2.*cos(phi)=-2.*v, wlap = -2.*w
!         (i.e., L(v,w) = -2.*(v,w) so (v,w) is an eigenfunction for the
!         vector Laplacian with eigenvalue -2.
!
!     (3) compute the coefficients br,bi,cr,ci of (v,w) using vector analysis
!
!     (3) compute the vector laplacian of (v,w) using vlapec,vlapes,vlapgc,vlapgs
!
!     (4) compare (3) with (2)
!
!     (5) invert (4) and compare with (v,w)
!
program tvlap

    use, intrinsic :: iso_fortran_env, only: &
        ip => INT32, &
        wp => REAL64, &
        stdout => OUTPUT_UNIT

    use spherepack_library, only: &
        Sphere, &
        Regularsphere, &
        GaussianSphere

    ! Explicit typing only
    implicit none

    !----------------------------------------------------------------------
    ! Dictionary
    !----------------------------------------------------------------------
    type (GaussianSphere) :: gaussian_sphere
    type (RegularSphere)  :: regular_sphere
    !----------------------------------------------------------------------

    call test_vector_laplacian_routines( gaussian_sphere )
    call test_vector_laplacian_routines( regular_sphere )


contains

    subroutine test_vector_laplacian_routines( sphere_type )
        !----------------------------------------------------------------------
        ! Dictionary: calling arguments
        !----------------------------------------------------------------------
        class (Sphere), intent (in out) :: sphere_type
        !----------------------------------------------------------------------
        ! Dictionary: local variables
        !----------------------------------------------------------------------
        integer (ip), parameter        :: NLONS = 16
        integer (ip), parameter        :: NLATS = 29
        integer (ip)                   :: i, j, k !! Counters
        real (wp)                      :: original_polar_component(NLATS,NLONS)
        real (wp)                      :: original_azimuthal_component(NLATS,NLONS)
        real (wp)                      :: exact_polar_laplacian(NLATS,NLONS)
        real (wp)                      :: exact_azimuthal_laplacian(NLATS,NLONS)
        real (wp)                      :: polar_component(NLATS,NLONS)
        real (wp)                      :: azimuthal_component(NLATS,NLONS)
        real (wp)                      :: approximate_polar_laplacian(NLATS,NLONS)
        real (wp)                      :: approximate_azimuthal_laplacian(NLATS,NLONS)
        character (len=:), allocatable :: previous_polar_laplacian_error
        character (len=:), allocatable :: previous_polar_inversion_error
        character (len=:), allocatable :: previous_azimuthal_laplacian_error
        character (len=:), allocatable :: previous_azimuthal_inversion_error
        !----------------------------------------------------------------------

        !
        !==> Set up workspace arrays
        !
        select type (sphere_type)
            !
            !==> For gaussian sphere
            !
            class is (GaussianSphere)

            !  Initialize gaussian sphere object
            call sphere_type%create(nlat=NLATS, nlon=NLONS)

            ! Allocate known error from previous platform
            allocate( previous_polar_laplacian_error, source='     polar laplacian error     = 1.760814e-12' )
            allocate( previous_azimuthal_laplacian_error, source='     azimuthal laplacian error = 8.715251e-13' )
            allocate( previous_polar_inversion_error, source='     polar inversion error     = 6.661338e-16' )
            allocate( previous_azimuthal_inversion_error, source='     azimuthal inversion error = 7.216450e-16' )
            !
            !==> For regular sphere
            !
            class is (RegularSphere)

            ! Initialize regular sphere
            call sphere_type%create(nlat=NLATS, nlon=NLONS)

            ! Allocate known error from previous platform
            allocate( previous_polar_laplacian_error, source='     polar laplacian error     = 3.113065e-13' )
            allocate( previous_azimuthal_laplacian_error, source='     azimuthal laplacian error = 4.702905e-13' )
            allocate( previous_polar_inversion_error, source='     polar inversion error     = 5.551115e-16' )
            allocate( previous_azimuthal_inversion_error, source='     azimuthal inversion error = 5.551115e-16' )
        end select

        !
        !==> test all vector laplacian and inverse vector laplacian subroutines
        !
        associate( &
            r => sphere_type%unit_vectors%radial, &
            phi => sphere_type%unit_vectors%azimuthal, &
            ve => original_polar_component, &
            we => original_azimuthal_component, &
            velap => exact_polar_laplacian, &
            welap => exact_azimuthal_laplacian &
            )
            do j=1, NLONS
                do i=1, NLATS
                    associate( &
                        cost => r(i,j)%z, &
                        cosp => phi(i,j)%y, &
                        sinp => -phi(i,j)%x &
                        )
                        !
                        !==> set vector field v,w
                        !
                        ve(i,j) = cosp
                        we(i,j) = -cost*sinp
                        !
                        !==> set vector laplacian vlap, wlap
                        !
                        velap(i,j) = -2.0_wp * ve(i,j)
                        welap(i,j) = -2.0_wp * we(i,j)
                    end associate
                end do
            end do
        end associate

        !
        !==> Compute vector laplacian
        !
        associate( &
            ve => original_polar_component, &
            we => original_azimuthal_component, &
            vlap => approximate_polar_laplacian, &
            wlap => approximate_azimuthal_laplacian &
            )
            call sphere_type%get_laplacian(ve, we, vlap, wlap)
        end associate

        !
        !==> Compute laplacian error
        !
        associate( &
            velap => exact_polar_laplacian, &
            welap => exact_azimuthal_laplacian, &
            vlap => approximate_polar_laplacian, &
            wlap => approximate_azimuthal_laplacian &
            )
            associate( &
                err2v => maxval(abs(vlap - velap)), &
                err2w => maxval(abs(wlap - welap)) &
                )

                !
                !==> Print earlier output from platform with 64-bit floating point
                !    arithmetic followed by the output from this computer
                !
                write( stdout, '(A)') ''
                write( stdout, '(A)') '     tvlap *** TEST RUN *** '
                write( stdout, '(A)') ''
                write( stdout, '(A)') '     grid type = '//sphere_type%grid%grid_type
                write( stdout, '(A)') '     Testing vector laplacian'
                write( stdout, '(2(A,I2))') '     nlat = ', NLATS,' nlon = ', NLONS
                write( stdout, '(A)') '     Previous 64 bit floating point arithmetic result '
                write( stdout, '(A)') previous_polar_laplacian_error
                write( stdout, '(A)') previous_azimuthal_laplacian_error
                write( stdout, '(A)') '     The output from your computer is: '
                write( stdout, '(A,1pe15.6)') '     polar laplacian error     = ', err2v
                write( stdout, '(A,1pe15.6)') '     azimuthal laplacian error = ', err2w
                write( stdout, '(A)' ) ''
            end associate
        end associate
        !
        !==> Now recompute (v,w) inverting (velap,welap)
        !
        associate( &
            v => polar_component, &
            w => azimuthal_component, &
            velap => exact_polar_laplacian, &
            welap => exact_azimuthal_laplacian &
            )
            call sphere_type%invert_laplacian( velap, welap, v, w )
        end associate

        !
        !==> compare this v,w with original
        !
        associate( &
            ve => original_polar_component, &
            we => original_azimuthal_component, &
            v => polar_component, &
            w => azimuthal_component &
            )
            associate( &
                err2v => maxval(abs(v - ve)), &
                err2w => maxval(abs(w - we)) &
                )
                !
                !==> Print earlier output from platform with 64-bit floating point
                !    arithmetic followed by the output from this computer
                !
                write( stdout, '(A)') ''
                write( stdout, '(A)') '     tvlap *** TEST RUN *** '
                write( stdout, '(A)') ''
                write( stdout, '(A)') '     grid type = '//sphere_type%grid%grid_type
                write( stdout, '(A)') '     Testing vector laplacian inversion'
                write( stdout, '(2(A,I2))') '     nlat = ', NLATS,' nlon = ', NLONS
                write( stdout, '(A)') '     Previous 64 bit floating point arithmetic result '
                write( stdout, '(A)') previous_polar_inversion_error
                write( stdout, '(A)') previous_azimuthal_inversion_error
                write( stdout, '(A)') '     The output from your computer is: '
                write( stdout, '(A,1pe15.6)') '     polar inversion error     = ', err2v
                write( stdout, '(A,1pe15.6)') '     azimuthal inversion error = ', err2w
                write( stdout, '(A)' ) ''
            end associate
        end associate
        !
        !==> Release memory
        deallocate( previous_polar_laplacian_error )
        deallocate( previous_polar_inversion_error )
        deallocate( previous_azimuthal_laplacian_error )
        deallocate( previous_azimuthal_inversion_error )
        call sphere_type%destroy()

    end subroutine test_vector_laplacian_routines

end program tvlap

