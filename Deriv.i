%module "Math::GSL::Deriv"
/*
struct gsl_function_struct 
{
  double (* function) (double x, void * params);
  void * params;
};

typedef struct gsl_function_struct gsl_function ;
#define GSL_FN_EVAL(F,x) (*((F)->function))(x,(F)->params)
*/

%include "typemaps.i"
%include "gsl_typemaps.i"
%{
    static HV * Callbacks = (HV*)NULL;
    typedef struct callback_t
    {  
        SV * obj;
    };
    double xsquared(double x,void *params){
        fprintf(stderr,"static xsquared!!\n");
        return x * x;
    }
%}
%apply double * OUTPUT { double *abserr, double *result };
/*
int gsl_deriv_central (const gsl_function *f,
                       double x, double h,
                       double *result, double *abserr);
*/
%typemap(in) gsl_function const * {
    fprintf(stderr,"typemap in!\n");
    gsl_function F;
    int count;
    F.params = 0;
    F.function = &xsquared;
    SV * callback;

    if (!SvROK($input)) {
        croak("Math::GSL : not a reference value!");
    }
    if (Callbacks == (HV*)NULL)
        Callbacks = newHV();

    hv_store( Callbacks, (char*)&$input, sizeof($input), newSVsv($input), 0 );
   
    //Perl_sv_dump( $input );
    // how to register callback ?
    $1 = &F;
};

%typemap(argout) gsl_function const * {
    fprintf(stderr,"typemap out!\n");
    SV ** sv;
    sv = hv_fetch(Callbacks, (char*)&$input, sizeof($input), FALSE );
    double x;

    if (sv == (SV**)NULL)
        croak("Math::GSL : Missing callback!\n");
    /*
    dSP;
    ENTER;
    SAVETMPS;
    */

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv((int)$input)));
    PUTBACK;


    fprintf(stderr, "\nCALLBACK!\n");
    
    call_sv(*sv, G_SCALAR);     /* The money shot */
    x = POPn;
    $result =  &x;
    fprintf(stderr, "x = %.8f", x);
    /*
    FREETMPS;
    LEAVE;
    */
}

%typemap(in) void * {
    $1 = (double *) $input;
};
%{
    #include "gsl/gsl_math.h"
    #include "gsl/gsl_deriv.h"
%}

%include "gsl/gsl_math.h"
%include "gsl/gsl_deriv.h"

%perlcode %{
@EXPORT_OK = qw/
               gsl_deriv_central 
               gsl_deriv_backward 
               gsl_deriv_forward 
             /;
%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

__END__

=head1 NAME

Math::GSL::Deriv - Functions to compute numerical derivatives by finite differencing

=head1 SYNOPSIS

This module is not yet implemented. Patches Welcome!

use Math::GSL::Deriv qw /:all/;

=head1 DESCRIPTION

Here is a list of all the functions in this module :

=over 

=item * C<gsl_deriv_central> 

=item * C<gsl_deriv_backward> 

=item * C<gsl_deriv_forward> 

=back

For more informations on the functions, we refer you to the GSL offcial
documentation: L<http://www.gnu.org/software/gsl/manual/html_node/>

Tip : search on google: site:http://www.gnu.org/software/gsl/manual/html_node/ name_of_the_function_you_want


=head1 AUTHORS

Jonathan Leto <jonathan@leto.net> and Thierry Moisan <thierry.moisan@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Jonathan Leto and Thierry Moisan

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

%}

